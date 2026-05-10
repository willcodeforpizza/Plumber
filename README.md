 ![Plumber-banner](docs/images/Plumber-banner.png)

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
| Code quality | `CodeQuality` | `PSScriptAnalyzer`, `Backticks`, `LineLength`, Pester tasks, `CodeCoverage` |
| Release hygiene | `ReleaseHygiene` | `ModuleVersion`, `Changelog` |
| Content | `Content` | `JSON`, `JSONSchema`, `YAML` |
| Module conventions | `ModuleConventions` | `Manifest`, `PublicFunctions`, `Structure`, `Naming`, `ToDo`, `Help` |

`Validate` runs all four parent tasks:

```powershell
Invoke-Plumber
Invoke-Plumber -Task Validate
```

Run a subset while iterating:

```powershell
Invoke-Plumber -Task CodeQuality
Invoke-Plumber -Task Backticks
Invoke-Plumber -Task LineLength
Invoke-Plumber -Task Content
Invoke-Plumber -Task PesterUnit
Invoke-Plumber -Task YAML
```

Choose an output mode:

```powershell
Invoke-Plumber -OutputMode Summary
Invoke-Plumber -OutputMode Table
Invoke-Plumber -OutputMode Json
Invoke-Plumber -OutputMode Raw
```

`Summary` is the default quiet output. `Table` prints every task result, `Json` emits structured
output for automation, and `Raw` preserves Invoke-Build output for debugging.
Failed validation throws after writing the selected output so CI can fail correctly.

Choose a build file explicitly when a repository has more than one build file:

```powershell
Invoke-Plumber -BuildFile ./MyModule.build.ps1
```

## To run

- Install or import the module.
- Browse to the module you want to validate.
- Add a build file to the root of your module, for example `MyModule.build.ps1`.
- Run `Invoke-Plumber`.

Example build file:

```powershell
./MyModule.build.ps1
--------------------

Import-Module Plumber

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest     = 'MyModule.psd1'
    CoverageMinimum    = 75
    IncludeTestsInPssa = $true
    JsonSchemas        = @()
    MaxLineLength      = 115
    PrivateHelpSynopsisOnly = $true
    SkipTasks          = @()
}
```

You can also run the same tasks through Invoke-Build:

```powershell
Invoke-Build Validate ./MyModule.build.ps1
```

## Configuration

| Key | Default | Description |
| --- | --- | --- |
| `ModuleManifest` | First `*.psd1` in the build root | Module manifest path. Explicit config is recommended. |
| `CoverageMinimum` | `75` | Minimum acceptable Pester coverage percentage. |
| `IncludeTestsInPssa` | `$true` | Include files under `Tests/` when running PSScriptAnalyzer. |
| `JsonSchemas` | `@()` | JSON file glob and schema mappings for `JSONSchema`. |
| `MaxLineLength` | `115` | Maximum line length for `LineLength`. |
| `PrivateHelpSynopsisOnly` | `$true` | Only require synopsis help for private functions. |
| `SkipTasks` | `@()` | Task names to exclude from the loaded task graph. |

`ModuleManifest` is recommended even though Plumber can fall back to discovery. Being explicit
avoids surprises in repos with analyzer settings, fixtures, examples or other data files.

`SkipTasks` removes tasks before Invoke-Build runs. Skipping a superset task skips all of its
children, for example `Content` skips `JSON`, `JSONSchema` and `YAML`. If all children of a
parent task are skipped, the parent task is not loaded.

Example config overrides:

```powershell
# Skip one child task
SkipTasks = @('YAML')

# Skip the Content task group
SkipTasks = @("Content")

# Require higher code coverage
CoverageMinimum = 90

# Allow longer lines
MaxLineLength = 140
```

Example JSON schema config:

```powershell
JsonSchemas = @(
    @{
        Path   = 'Resource/*.json'
        Schema = 'Resource/Schema/config.schema.json'
    }
)
```

## Task notes

- `CodeCoverage` uses `CoverageMinimum`.
- `JSONSchema` uses `JsonSchemas`.
- `LineLength` uses `MaxLineLength`.
- `PSScriptAnalyzer` uses `IncludeTestsInPssa`.
- `Help` uses `PrivateHelpSynopsisOnly`.
- `Manifest`, `ModuleVersion` and `Naming` use `ModuleManifest`.
- Parent validation tasks aggregate child failures so all checks can report in one run.

 ![Plumber-bottom-banner](docs/images/Plumber-bottom-banner.png)
