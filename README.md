 ![Plumber-banner](docs/images/Plumber-banner.png)

# Plumber

A set of Invoke-Build tasks for PowerShell validation pipelines.

Plumber provides shared validation tasks you can import into module build files so local runs,
CI, and agent workflows use the same checks.

Documentation: https://willcodeforpizza.github.io/Plumber/

## Requirements

- Windows or Linux
- PowerShell 7

## Install

```powershell
Install-Module Plumber -Scope CurrentUser
```

## To run

- Browse to the module you want to validate.
- Add a build file to the root of your module `MyModule.build.ps1` (see configuration below).
- Run `Invoke-Plumber`.

### Configuration

Create a `build.ps1` in the root of the module. This is the basic configuration you need to get running:

```powershell
./MyModule.build.ps1
--------------------

Import-Module Plumber

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

To customize the tasks you run, or edit settings, set configuration in the build file.

Check the [task index](docs/tasks/index.md) for details on each task configuration. Here is an example of all available options:

```powershell
./MyModule.build.ps1
--------------------

Import-Module Plumber

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    FileScope      = 'All'
    DiffBase       = $null
    Tasks          = @{
        Exclude              = @(
            'Backticks',
            'ToDo'
        )
        Local                = @(
            'Tasks/ValidateTaskDocs.ps1'
            'Tasks/CheckGeneratedFiles.ps1'
        )
        CodeCoverage         = @{
            Minimum = 75
        }
        Help                 = @{
            PrivateSynopsisOnly = $true
        }
        JSONSchema           = @{
            Schemas = @(
                @{
                    Path   = 'Resource/*.json'
                    Schema = 'Resource/Schema/config.schema.json'
                }
            )
        }
        LineLength           = @{
            MaxLength = 80
        }
        PSScriptAnalyzer     = @{
            IncludeTests = $false
            Exclude      = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
        PublicFunctionPrefix = @{
            Prefix     = 'MyModule'
            Exclusions = @(
                'New-Thing'
            )
        }
    }
}
```

Use `Tasks.Local` for project-specific validation that should run as part of
`Validate` without becoming a Plumber core task. See
[Local tasks](docs/local-tasks.md).

You can also run the same tasks through Invoke-Build:

```powershell
Invoke-Build Validate ./MyModule.build.ps1
```

Warning: When running directly through `Invoke-Build` be aware that Plumber tasks run with `?TaskName`. This means "Continue on error" so the entire pipeline completes. Be careful with your error handling. Use `Invoke-Plumber` for concrete error behavior.

## Running tasks

`Validate` runs all validation tasks:

```powershell
cd ./MyModule
Invoke-Plumber

# Or explicitly
Invoke-Plumber -Task Validate
```

Run a subset group or individual tasks:

```powershell
Invoke-Plumber -Task CodeQuality
Invoke-Plumber -Task Content

Invoke-Plumber -Task PesterUnit
Invoke-Plumber -Task Backticks
Invoke-Plumber -Task LineLength
Invoke-Plumber -Task YAML
```

## Output

Choose an output mode:

```powershell
Invoke-Plumber -OutputMode Summary
Invoke-Plumber -OutputMode Table
Invoke-Plumber -OutputMode Json
Invoke-Plumber -OutputMode Raw
Invoke-Plumber -OutputMode CI
```

`Summary` is the default quiet output. `Table` prints every task result, `Json` emits structured
output for automation, `Raw` preserves Invoke-Build output for debugging, and `CI`
preserves Invoke-Build output with a concise final summary.

Failed validation throws after writing the selected output so CI can fail correctly.

Choose a build file explicitly when a repository has more than one build file:

```powershell
Invoke-Plumber -BuildFile ./MyModule.build.ps1
```

## Tasks

Tasks are documented in detail in the [task index](docs/tasks/index.md).

### Groups

| Group | Includes |
| --- | --- |
| [CodeQuality](docs/tasks/CodeQuality.md) | `PSScriptAnalyzer`, `Backticks`, `LineLength`, `PesterUnit`, `PesterIntegration`, `CodeCoverage` |
| [Content](docs/tasks/Content.md) | `JSON`, `JSONSchema`, `YAML` |
| [ModuleConventions](docs/tasks/ModuleConventions.md) | `Manifest`, `PublicFunctions`, `Naming`, `ToDo`, `Help` |
| [ReleaseHygiene](docs/tasks/ReleaseHygiene.md) | `ModuleVersion`, `ChangelogUpdated` |
| [Validate](docs/tasks/Validate.md) | `CodeQuality`, `ReleaseHygiene`, `Content`, `ModuleConventions` |

### Validation Tasks

| Task | Group |
| --- | --- |
| [Backticks](docs/tasks/Backticks.md) | `CodeQuality` |
| [CodeCoverage](docs/tasks/CodeCoverage.md) | `CodeQuality` |
| [LineLength](docs/tasks/LineLength.md) | `CodeQuality` |
| [PesterIntegration](docs/tasks/PesterIntegration.md) | `CodeQuality` |
| [PesterUnit](docs/tasks/PesterUnit.md) | `CodeQuality` |
| [PSScriptAnalyzer](docs/tasks/PSScriptAnalyzer.md) | `CodeQuality` |
| [JSON](docs/tasks/JSON.md) | `Content` |
| [JSONSchema](docs/tasks/JSONSchema.md) | `Content` |
| [YAML](docs/tasks/YAML.md) | `Content` |
| [Help](docs/tasks/Help.md) | `ModuleConventions` |
| [Manifest](docs/tasks/Manifest.md) | `ModuleConventions` |
| [Naming](docs/tasks/Naming.md) | `ModuleConventions` |
| [PublicFunctions](docs/tasks/PublicFunctions.md) | `ModuleConventions` |
| [ToDo](docs/tasks/ToDo.md) | `ModuleConventions` |
| [ChangelogUpdated](docs/tasks/ChangelogUpdated.md) | `ReleaseHygiene` |
| [ModuleVersion](docs/tasks/ModuleVersion.md) | `ReleaseHygiene` |

## Configuration

Configuration is defined in the build file, in the hashtable passed to `Get-PlumberTaskLoader`.

Review the details per task help in the [task index](docs/tasks/index.md).

### Global

#### Tasks.Exclude

`Tasks.Exclude` removes tasks before `Invoke-Build` runs. Excluding a group task excludes all of
its children, for example `Content` excludes `JSON`, `JSONSchema` and `YAML`. If all children of a
parent task are excluded, the parent task is not loaded.

You can also exclude individual tasks.

#### Tasks.<Task>.Exclude

`Tasks.<Task>.Exclude` is task-scoped. A file excluded from one task can still be used by another
task.

For example, to exclude a test asset from PSScriptAnalyzer, you would do:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
    }
}
```

Review the details per task help in the [task index](docs/tasks/index.md) for details on what tasks support path exclusions.

Patterns use PowerShell wildcard matching against repository-relative paths
normalized with `/`.

#### FileScope

`FileScope` controls which files are returned by Plumber's shared file
discovery. The default is `All`.

Set `FileScope` to `Changed` to validate only files changed in git. This
includes staged changes, unstaged changes and untracked files. Deleted files are
ignored.

Local development example:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    FileScope = 'Changed'
}
```

Pull request validation example:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    FileScope = 'Changed'
    DiffBase  = 'origin/main'
}
```

Changed-file scope applies only to tasks that use `Get-PlumberTaskFile`, such as
`PSScriptAnalyzer`, `Backticks`, `LineLength`, `ToDo`, `JSON`, `JSONSchema` and
`YAML`. Pester and module-wide checks still run normally.

When changed-file scope is active, Plumber writes how many changed files were
selected before task-specific filters are applied.



 ![Plumber-bottom-banner](docs/images/Plumber-bottom-banner.png)
