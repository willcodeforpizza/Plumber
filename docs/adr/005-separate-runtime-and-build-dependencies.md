# 005: Separate Runtime and Build Dependencies

## Status

Accepted

## Context

PowerShell module manifests support dependency declarations such as
`RequiredModules` and `ModuleList`, but those declarations affect normal module
consumers. Plumber and Plumber.Release are build and release tooling for module
maintainers, not runtime requirements for people importing a module such as
PSPiHole or Homelab.

Using manifest dependency declarations for Plumber tooling forces normal module
consumers to install build-only modules. `RequiredModules` also loads modules in
global scope, which makes build dependency behavior harder to reason about and
can interfere with test isolation.

Plumber itself has internal task dependencies that must be available before its
tasks can run. Repositories can also have task dependencies that are only needed
for validation or release tasks. For example, a repository that uses
Plumber.Release may need `Microsoft.PowerShell.PSResourceGet` for publishing,
but that dependency is not needed to import the module at runtime.

## Decision

Plumber will separate dependency concerns:

- Runtime module manifests should declare only real runtime dependencies.
- Plumber's own task dependencies remain internal to Plumber.
- Repository build and release dependencies are declared in
  `Plumber.dependencies.psd1` at the repository root.
- Repository dependencies are installed explicitly with
  `Install-PlumberDependency`.

Loading a consumer module must not install build tooling as a side effect.

CI can opt into installing missing Plumber internal dependencies when importing
Plumber:

```powershell
Import-Module Plumber -ArgumentList @{ InstallMissingDependencies = $true }
```

After Plumber is loaded, CI can install repository task dependencies:

```powershell
Install-PlumberDependency
Invoke-Plumber -OutputMode CI
```

This keeps install behavior explicit while still allowing clean CI agents to set
up all validation and release tooling before invoking Plumber tasks.

## Alternatives Considered

Plumber could require downstream modules to list Plumber and Plumber.Release in
their module manifests. This makes build tooling visible to normal consumers and
can require users to install modules they do not need at runtime.

Plumber could use `RequiredModules` for build tooling. This delegates loading to
PowerShell, but it loads dependencies in global scope and makes the import
behavior less isolated.

Plumber.Release could install its own publishing dependencies when
`PublishModule` runs. This hides installation inside a task and duplicates
dependency policy that belongs in Plumber.

Plumber could install repository dependencies automatically when imported. This
would surprise users by performing installation during module import, and it
would make import behavior depend on network and gallery availability.

## Consequences

Normal module consumers do not need to install Plumber, Plumber.Release, or
other build tooling unless those modules are true runtime dependencies.

Build and release dependencies are visible in one repository-level file and can
be installed explicitly by local developers or CI.

Clean CI agents need a setup step that imports Plumber with dependency
installation enabled and then runs `Install-PlumberDependency`.

Plumber.Release can assume Plumber loaded it as task tooling, but it should not
install its own dependencies. If a task dependency such as PSResourceGet is
missing, Plumber.Release should fail clearly and point users to
`Install-PlumberDependency`.
