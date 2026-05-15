# Writing Tasks

Plumber tasks run inside an Invoke-Build pipeline loaded by `Tasks/TaskLoader.ps1`.
Task files should stay small and should use Plumber helper functions for shared
behavior.

## File Discovery

Tasks that inspect files should use `Get-PlumberTaskFile` instead of calling
`Get-ChildItem -Recurse` directly.

```powershell
$files = Get-PlumberTaskFile -Task Backticks -Extension '.ps1', '.psm1', '.psd1'
```

`Get-PlumberTaskFile` caches the build-root file list for the current run,
applies `FileScope = 'Changed'` when configured, applies optional extension and
path filters, and applies task-scoped `Tasks.<Task>.Exclude` configuration.

## Task Exclusions

`Tasks.<Task>.Exclude` is task-scoped. A file excluded from one task can still be
used by another task.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        Backticks        = @{
            Exclude = @('Tests/Assets/TaskHelp/*')
        }
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
    }
}
```

Patterns use PowerShell wildcard matching against repository-relative paths
normalized with `/`.

## Helper Scope

Plumber can validate itself, and self-validation can reload module state while
tasks are running. A task that depends on a private helper should reload that
helper defensively when the command is missing.

```powershell
if (-not (Get-Command Get-PlumberTaskFile -ErrorAction SilentlyContinue)) {
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Test-PlumberTaskPathExcluded.ps1')
    . (Join-Path $script:PlumberConfig.ModuleRoot 'Private/Get-PlumberTaskFile.ps1')
}
```

## Existing Semantics

When moving a task to shared file discovery, preserve the task's existing file
selection behavior. For example, `JSON` validates direct files under `Resource`,
while `YAML` scans recursively across the build root.

## Task Help

Document each task with the custom Plumber help schema in the comment block
above `Add-BuildTask`. The generated task pages are built from these comments.

Every documented task should include `.SYNOPSIS`, `.DESCRIPTION`, and `.RUN`.

````powershell
<#
    .SYNOPSIS
    Validates YAML files.

    .DESCRIPTION
    Finds `.yml` and `.yaml` files under the build root and verifies that each
    file can be parsed from YAML and serialized back to YAML.

    .GROUP
    Content

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task YAML
    ```
#>
Add-BuildTask -Name YAML -Jobs {
}
````

Group tasks should use `.INCLUDES` and `.RUN`. They should not use `.GROUP`,
`.PASS`, or `.FAIL`.

````text
.INCLUDES
JSON
JSONSchema
YAML

.RUN
```powershell
Invoke-Plumber -Task Content
```
````

Leaf validation tasks should use `.GROUP`, `.CONFIGURATION`, `.RUN`, `.PASS`,
and `.FAIL`. Keep pass and fail examples short and focused on the behavior the
task validates.

## Configuration Help

Use `.CONFIGURATION` for config that changes the task's behavior. Include
task-specific `Tasks.<Task>.Exclude` when the task uses `Get-PlumberTaskFile`.

Use `### Example` as the configuration example heading so the generated
Markdown nests it under `## Configuration`.

````text
.CONFIGURATION
`Tasks.LineLength.MaxLength` controls the maximum allowed line length. The
default is `115`.

`Tasks.LineLength.Exclude` excludes matching files from this task.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks = @{
        LineLength = @{
            MaxLength = 80
            Exclude   = @('Tests/Assets/LongLines.ps1')
        }
    }
}
```
````

Do not include graph config such as `Tasks.Exclude` in each task page.
Document global config once in global user documentation.

## Help Examples

Examples in task help are still part of Plumber's source tree. Make sure
examples do not cause Plumber's own validation tasks to fail.

- Do not include a literal trailing backtick in a PowerShell code block.
- Avoid examples that look like real TODO comments in PowerShell source files.
- Avoid very long physical lines in task comments.
- Prefer `text` fences when showing a failing shape would trigger a validation
  task in the source file.

Run `GenerateDocs` after editing task help:

```powershell
Invoke-Build -File ./Plumber.build.ps1 -Task GenerateDocs
```

Generated task pages are written to `docs/tasks`, including `docs/tasks/index.md`.
