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
applies optional extension and path filters, and applies task-scoped
`ExcludePaths` configuration.

## Task Exclusions

`ExcludePaths` is task-scoped. A file excluded from one task can still be used by
another task.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ExcludePaths = @{
        Backticks        = @('Tests/Assets/TaskHelp/*')
        PSScriptAnalyzer = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
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
