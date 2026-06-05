# 005: Separate Runtime and Build Dependencies

## Status

Accepted (revised)

## Context

PowerShell module manifests support dependency declarations such as
`RequiredModules` and `ModuleList`, but those declarations affect normal module
consumers. Plumber and Plumber.Release are build and release tooling for module
maintainers, not runtime requirements for people importing a module such as
PSPiHole or Homelab.

Using manifest dependency declarations for Plumber-backed build tooling forces
normal module consumers to install build-only modules. `RequiredModules` also
imports listed modules into the caller's global session state when the parent
module loads, which can leak build-only commands such as `Invoke-Pester` and
`Invoke-ScriptAnalyzer` into the consumer's session and interfere with test
isolation.

Plumber itself has internal task dependencies that must be available before its
tasks can run. Repositories can also have task dependencies that are only needed
for validation or release tasks. For example, a repository that uses
Plumber.Release may need publishing modules, but those dependencies are not
needed to import the module under test at runtime.

## Decision

Plumber separates dependency concerns:

- Runtime module manifests should declare only real runtime dependencies.
- Plumber's own task dependencies are declared in
  `Plumber.internal.dependencies.psd1`, bundled inside the Plumber
  module.
- Repository build and release dependencies are declared in
  `Plumber.dependencies.psd1` at the repository root.
- `Install-PlumberDependency` installs Plumber's own internal task dependencies
  by default.
- `Install-PlumberDependency -Build` installs the calling repository's build and
  release dependencies from its root `Plumber.dependencies.psd1`.
- `Import-Module Plumber` never installs dependencies as a side effect and does
  not enter a partial/bootstrap-only state. It exposes the full Plumber command
  surface. Commands that need Plumber task dependencies validate/import them at
  the command boundary and fail clearly if they are missing.

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
internal dependency file replaces that use.

### Bootstrap flow

Clean machine bootstrap:

```powershell
Install-Module Plumber -Scope CurrentUser
Import-Module Plumber
Install-PlumberDependency
Invoke-Plumber
```

Repository/CI bootstrap:

```powershell
Import-Module ./Plumber.psd1 -Force
Install-PlumberDependency
Install-PlumberDependency -Build -Path .
Invoke-Plumber -OutputMode CI
```

If Plumber's internal task dependencies are missing and a caller runs
`Invoke-Plumber`, the command fails with a message pointing to
`Install-PlumberDependency`.

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
installation.

Plumber could partially import when dependencies are missing, export only the
installer, and require a second import after installation. This avoids
install-on-import, but creates a confusing state where `Import-Module Plumber`
succeeds even though normal commands such as `Invoke-Plumber` are missing.
Plumber instead imports fully and fails at command boundaries that actually need
task dependencies.

Plumber.Release could install its own publishing dependencies when
`PublishModule` runs. This hides installation inside a task and duplicates
dependency policy that belongs in Plumber-backed repository setup.

Plumber could install repository dependencies automatically when imported. This
would surprise users by performing installation during module import, and it
would make import behavior depend on network and gallery availability.

## Consequences

Normal module consumers do not need to install Plumber, Plumber.Release, or
other build tooling unless those modules are true runtime dependencies.

Build and release dependencies are visible in explicit dependency files and can
be installed by local developers or CI.

Clean CI agents need an explicit bootstrap step that imports Plumber, runs
`Install-PlumberDependency`, runs `Install-PlumberDependency -Build`, and then
runs `Invoke-Plumber`.

Plumber.Release can assume repository setup installed it as task tooling, but it
should not install its own dependencies. If a task dependency is missing,
Plumber.Release should fail clearly and point users to `Install-PlumberDependency -Build`.
