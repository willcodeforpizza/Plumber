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

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

To customize the tasks you run, or edit settings, set configuration in the build file.

Check the [task index](docs/tasks/index.md) for details on each task configuration. Here is an example of all available options:

```powershell
./MyModule.build.ps1
--------------------

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

`Invoke-Build` is not the recommended way to run Plumber tasks because Plumber
wraps details such as error handling and module import/discovery. If you want to
run Invoke-Build directly, ensure Plumber is loaded first:

```powershell
Import-Module Plumber
Invoke-Build -File ./MyModule.build.ps1 Validate
```

This should work for simple cases, but direct Invoke-Build execution is not
officially supported.

## Dependencies

Plumber has two dependency paths:

- Plumber's own task dependencies are internal to Plumber. When CI needs a
  clean agent to install missing Plumber dependencies during module import, use:

  ```powershell
  Import-Module Plumber -ArgumentList @{ InstallMissingDependencies = $true }
  ```

- Repository build or release dependencies belong in `Plumber.dependencies.psd1`
  at the repository root. These are dependencies needed to run that repository's
  Plumber tasks, not runtime dependencies for normal users of the module.

Example `Plumber.dependencies.psd1`:

```powershell
@{
    Modules = @(
        @{
            ModuleName    = 'Plumber.Release'
            ModuleVersion = '0.1.4'
        }
    )
}
```

Install the repository dependencies explicitly before running tasks:

```powershell
Install-PlumberDependency
Invoke-Plumber
```

CI commonly does both steps: import Plumber with dependency installation enabled
for Plumber itself, then install the repository's task dependencies:

```powershell
Import-Module Plumber -ArgumentList @{ InstallMissingDependencies = $true }
Install-PlumberDependency
Invoke-Plumber -OutputMode CI
```

`Install-PlumberDependency` installs modules from `Plumber.dependencies.psd1`.
Loading a consumer module should not install build tooling or force normal users
to install Plumber. Keep Plumber and release tooling out of the module manifest
unless they are real runtime dependencies.

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
Invoke-Plumber -NoFormat
```

`Summary` is the default quiet output. `Table` prints every task result, `Json` emits structured
output for automation, `Raw` preserves Invoke-Build output for debugging, and `CI`
preserves Invoke-Build output with a concise final summary. Text output uses ANSI
formatting by default; add `-NoFormat` for plain text.

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
| [CodeQuality](docs/tasks/CodeQuality.md) | `PSScriptAnalyzer`, `Backticks`, `LineLength`, `PathSeparator`, `PesterUnit`, `PesterIntegration`, `CodeCoverage` |
| [Content](docs/tasks/Content.md) | `JSON`, `JSONSchema`, `YAML` |
| [ModuleConventions](docs/tasks/ModuleConventions.md) | `Manifest`, `PublicFunctions`, `PublicFunctionPrefix`, `FunctionFiles`, `Naming`, `ToDo`, `Help` |
| [ReleaseHygiene](docs/tasks/ReleaseHygiene.md) | `ModuleVersion`, `ChangelogUpdated` |
| [Validate](docs/tasks/Validate.md) | `CodeQuality`, `ReleaseHygiene`, `Content`, `ModuleConventions` |

### Validation Tasks

| Task | Group |
| --- | --- |
| [Backticks](docs/tasks/Backticks.md) | `CodeQuality` |
| [CodeCoverage](docs/tasks/CodeCoverage.md) | `CodeQuality` |
| [LineLength](docs/tasks/LineLength.md) | `CodeQuality` |
| [PathSeparator](docs/tasks/PathSeparator.md) | `CodeQuality` |
| [PesterIntegration](docs/tasks/PesterIntegration.md) | `CodeQuality` |
| [PesterUnit](docs/tasks/PesterUnit.md) | `CodeQuality` |
| [PSScriptAnalyzer](docs/tasks/PSScriptAnalyzer.md) | `CodeQuality` |
| [JSON](docs/tasks/JSON.md) | `Content` |
| [JSONSchema](docs/tasks/JSONSchema.md) | `Content` |
| [YAML](docs/tasks/YAML.md) | `Content` |
| [Help](docs/tasks/Help.md) | `ModuleConventions` |
| [FunctionFiles](docs/tasks/FunctionFiles.md) | `ModuleConventions` |
| [Manifest](docs/tasks/Manifest.md) | `ModuleConventions` |
| [Naming](docs/tasks/Naming.md) | `ModuleConventions` |
| [PublicFunctionPrefix](docs/tasks/PublicFunctionPrefix.md) | `ModuleConventions` |
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
