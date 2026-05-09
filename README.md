# Plumber

A set of Invoke-Build tasks for PowerShell validation pipelines.

Plumber provides shared validation tasks you can import into module build files so local runs,
CI, and agent workflows use the same checks.

## Requirements

- Windows or Linux
- PowerShell 7
- The modules listed in `./Resource/RequiredModules.json` if you use those tasks

## Task groups

| Category | Parent task | Child tasks |
| --- | --- | --- |
| Code quality | `CodeQuality` | `PSScriptAnalyzer`, `Pester`, `CodeCoverage` |
| Release hygiene | `ReleaseHygiene` | `ModuleVersion`, `Changelog` |
| Content | `Content` | `JSON`, `YAML` |
| Module conventions | `ModuleConventions` | `Manifest`, `PublicFunctions`, `Structure`, `Naming`, `ToDo` |

`Validate` runs all four parent tasks:

```powershell
Invoke-Plumber
Invoke-Plumber -Task Validate
```

Run a subset while iterating:

```powershell
Invoke-Plumber -Task CodeQuality
Invoke-Plumber -Task Content
Invoke-Plumber -Task Pester
Invoke-Plumber -Task YAML
```

## To run

- Install or import the module.
- Browse to the module you want to validate.
- Copy `./Plumber/Resource/ModuleName.build.ps1` to the root of your module.
- Rename it to match your module, for example `MyModule.build.ps1`.
- Run `Invoke-Plumber`.

## Notes

Plumber is intentionally plain Invoke-Build. The value is the shared task set and consistent
task names, not a separate build framework.
