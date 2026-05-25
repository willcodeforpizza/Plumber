# 005: Separate Runtime and Build Dependencies

## Status

Accepted (revised)

## Context

PowerShell module manifests support dependency declarations such as
`RequiredModules` and `ModuleList`, but those declarations affect normal module
consumers. Plumber and Plumber.Release are build and release tooling for module
maintainers, not runtime requirements for people importing a module such as
PSPiHole or Homelab.

Using manifest dependency declarations for Plumber tooling forces normal module
consumers to install build-only modules. `RequiredModules` also imports its
listed modules into the caller's global session state when the parent module
loads, which leaks build-only commands such as `Invoke-Pester` and
`Invoke-ScriptAnalyzer` into the consumer's session and can interfere with test
isolation.

Plumber itself has internal task dependencies that must be available before its
tasks can run. Repositories can also have task dependencies that are only
needed for validation or release tasks. For example, a repository that uses
Plumber.Release may need `Microsoft.PowerShell.PSResourceGet` for publishing,
but that dependency is not needed to import the module at runtime.

## Decision

Plumber separates dependency concerns:

- Runtime module manifests should declare only real runtime dependencies.
- Plumber's own task dependencies are declared in a `Plumber.dependencies.psd1`
  file that ships inside the Plumber module, alongside `Plumber.psd1`.
- Repository build and release dependencies are declared in
  `Plumber.dependencies.psd1` at the repository root (same schema, different
  location).
- Both files are installed by `Install-PlumberDependency`. The `-Internal`
  switch targets Plumber's own bundled file; the default targets a consumer
  repository's file.

### Why not the manifest

`RequiredModules` would install Plumber's dependencies transitively when a user
runs `Install-Module Plumber`, but it would also import those dependencies into
the caller's session whenever Plumber is loaded. That leaks `Invoke-Pester`,
`Invoke-ScriptAnalyzer`, `Invoke-Build`, and yaml cmdlets into every Plumber
consumer's session, which Plumber explicitly wants to avoid.

`NestedModules` imports into the parent module's scope but is not honoured by
`Install-Module` as an installable dependency list, so it does not solve the
install-time problem.

`ModuleList` is documented as inventory only — a hint with no install or load
behaviour. Earlier versions of Plumber repurposed `ModuleList` as an internal
dependency declaration, but this misused a documented field. The dedicated
`Plumber.dependencies.psd1` file replaces that use.

### Two-phase module import

`Plumber.psm1` loads in two phases:

1. **Bootstrap phase.** The .psm1 dot-sources `Import-PlumberDependency` and
   `Install-PlumberDependency` and attempts to import the dependencies listed
   in the bundled `Plumber.dependencies.psd1`. These two functions depend only
   on built-in cmdlets, so they load even when Plumber's task dependencies are
   missing.
2. **Full load.** If the bootstrap phase succeeds, the .psm1 dot-sources the
   remaining `Public/`, `Private/`, and `TaskFunctions/` files. If it fails,
   the .psm1 writes a warning naming `Install-PlumberDependency -Internal` as
   the bootstrap command, exports `Install-PlumberDependency` only, and
   returns. Importing Plumber never installs anything as a side effect.

Bootstrap on a clean machine:

```powershell
Install-Module Plumber -Scope CurrentUser
Import-Module Plumber                # warns; bootstrap surface only
Install-PlumberDependency -Internal  # installs Plumber's task deps
Import-Module Plumber -Force         # full load
```

CI extends this with the consumer-repo dependency install:

```powershell
Import-Module Plumber -Force
Install-PlumberDependency
Invoke-Plumber -OutputMode CI
```

### Installer choice

`Import-PlumberDependency` prefers `Install-PSResource` (PSResourceGet) when
present and falls back to `Install-Module` (PowerShellGet v2) otherwise. Both
stacks resolve from PSGallery and accept minimum-version semantics, which
matches how dependencies are declared.

Version comparisons use `System.Management.Automation.SemanticVersion` so
pre-release tags (e.g. `5.7.1-preview`) compare correctly.

## Alternatives Considered

Plumber could require downstream modules to list Plumber and Plumber.Release in
their module manifests. This makes build tooling visible to normal consumers
and can require users to install modules they do not need at runtime.

Plumber could use `RequiredModules` for build tooling. This would integrate
with `Install-Module Plumber` but would leak build-only commands into the
consumer's session at import time.

Plumber could keep the previous `Import-Module Plumber -ArgumentList @{
InstallMissingDependencies = $true }` shape. This worked but was undiscoverable
(no tab-complete, no `Get-Help`) and conflated module import with package
installation. Surfacing `Install-PlumberDependency -Internal` as a normal
cmdlet trades one extra command for a standard, discoverable interface.

Plumber.Release could install its own publishing dependencies when
`PublishModule` runs. This hides installation inside a task and duplicates
dependency policy that belongs in Plumber.

Plumber could install repository dependencies automatically when imported. This
would surprise users by performing installation during module import, and it
would make import behavior depend on network and gallery availability.

## Consequences

Normal module consumers do not need to install Plumber, Plumber.Release, or
other build tooling unless those modules are true runtime dependencies.

Build and release dependencies are visible in two files (one inside Plumber,
one at the consumer repo root) and can be installed explicitly by local
developers or CI.

Clean CI agents need a bootstrap step that imports Plumber once to expose the
installer, runs `Install-PlumberDependency -Internal`, and re-imports for a
full load before running `Install-PlumberDependency` and `Invoke-Plumber`.

Plumber.Release can assume Plumber loaded it as task tooling, but it should
not install its own dependencies. If a task dependency such as PSResourceGet
is missing, Plumber.Release should fail clearly and point users to
`Install-PlumberDependency`.
