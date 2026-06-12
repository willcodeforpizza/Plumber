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

To customize the tasks you run, or edit settings, set configuration in the build
file.

See [configuration](docs/configuration.md) for global settings and validation
behavior. Check the [task index](docs/tasks/index.md) for details on each task
configuration. Here is an example of all available options:

```powershell
./MyModule.build.ps1
--------------------

. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest       = 'MyModule.psd1'
    FileScope            = 'All'
    DiffBase             = $null
    IncludeModuleFolders = @()
    ExcludeDirectories   = @('.git')
    Tasks                = @{
        Backticks            = @{
            RunWhen = 'Never'
        }
        ToDo                 = @{
            RunWhen = 'Never'
        }
        ModuleVersion        = @{
            RunWhen = 'OnRelease'
        }
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

Plumber has two dependency paths, both handled by `Install-PlumberDependency`:

- **Plumber's own task dependencies** (Pester, PSScriptAnalyzer, InvokeBuild,
  powershell-yaml) ship inside the Plumber module in
  `Plumber.internal.dependencies.psd1`. Install these with
  `Install-PlumberDependency`.
- **Repository build or release dependencies** belong in
  `Plumber.dependencies.psd1` at the repository root. These are dependencies
  needed to run that repository's Plumber tasks, not runtime dependencies for
  normal users of the module. Install these with `Install-PlumberDependency -Build`.

On a clean machine, import Plumber, install Plumber's own task dependencies, then
run Plumber commands:

```powershell
Install-Module Plumber -Scope CurrentUser
Import-Module Plumber
Install-PlumberDependency
Invoke-Plumber
```

If task dependencies are missing and you run `Invoke-Plumber`, Plumber fails
with a clear message pointing back to `Install-PlumberDependency`. Importing
Plumber never installs dependencies as a side effect.

Example consumer-repo `Plumber.dependencies.psd1`:

```powershell
@{
    Modules = @(
        @{
            ModuleName    = 'Plumber.Release'
            ModuleVersion = '0.1.6'
        }
    )
}
```

Install the repository's build dependencies explicitly before running tasks:

```powershell
Install-PlumberDependency -Build
Invoke-Plumber
```

A typical CI bootstrap imports Plumber, installs Plumber's own dependencies,
installs the repository's task dependencies, then runs validation:

```powershell
Import-Module ./Plumber.psd1 -Force
Install-PlumberDependency
Install-PlumberDependency -Build -Path .
Invoke-Plumber -OutputMode CI
```

`Install-PlumberDependency` prefers `Install-PSResource` (PSResourceGet) when
available and falls back to `Install-Module` (PowerShellGet v2). Module imports
never install dependencies as a side effect. The `Install-Module` fallback does
not pass `-Force` or `-SkipPublisherCheck` by default; if your environment needs
publisher-check bypasses, make that policy explicit outside Plumber.
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

`Invoke-Plumber -OutputMode Json -NoFormat` writes one parseable JSON result object
to stdout for automation. The JSON contract is schema-locked in
[`docs/schemas/invoke-plumber-result.schema.json`](docs/schemas/invoke-plumber-result.schema.json)
and documented in [Invoke-Plumber JSON output contract](docs/json-output.md).

Failed validation throws after writing the selected output so CI can fail correctly.
For JSON mode, keep stdout and stderr separate: stdout contains the JSON result,
then the terminating error/non-zero exit follows; stderr is diagnostic only.

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

Configuration is defined in the build file, in the hashtable passed to
`Get-PlumberTaskLoader`.

Plumber validates built-in configuration when the task loader runs. Unknown
keys, invalid value types and out-of-range values fail before the task graph is
loaded. Typos close to a known key include a suggestion.

```text
Plumber config failed validation:
- Tasks.LineLenght is not a known task. Did you mean LineLength?
```

See [configuration](docs/configuration.md) for the full configuration guide.
Review per-task settings in the [task index](docs/tasks/index.md).

### Global

#### IncludeModuleFolders

`IncludeModuleFolders` adds extra module source folders to the default `Public`
and `Private` folders. Source-root tasks such as `PesterUnit` code coverage and
`FunctionFiles` use these folders.

Use this for module-owned source folders that should be treated like module
code:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    IncludeModuleFolders = @('TaskFunctions')
}
```

#### ExcludeDirectories

`ExcludeDirectories` lists directory names that Plumber's shared file discovery
skips entirely. The default is `@('.git')`, so version control internals are
never validated. Names match path segments at any depth under the build root.
Add build artifact directories such as `out` to exclude them too:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ExcludeDirectories = @('.git', 'out')
}
```

#### Tasks.<Task>.RunWhen

`Tasks.<Task>.RunWhen` controls when a task runs. `<Task>` can be a built-in
task, a group task, or the file stem of a local task. Supported values are:

- `Always` - run whenever the task is selected. This is the default.
- `OnRelease` - run only when `PLUMBER_RELEASE_INTENT=true`.
- `Never` - never run the task.

Use `Never` to disable a task or group:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        ToDo = @{
            RunWhen = 'Never'
        }
        ModuleVersion = @{
            RunWhen = 'OnRelease'
        }
        Content = @{
            RunWhen = 'Never'
        }
    }
}
```

`Tasks.Exclude` has been removed. Use `Tasks.<Task>.RunWhen = 'Never'` instead.

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

Review per-task help in the [task index](docs/tasks/index.md) for details on
what tasks support path exclusions.

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
