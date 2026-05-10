# Local Tasks

Plumber's built-in task graph stays focused on shared validation tasks. Projects
can add repository-specific validation without adding those tasks to Plumber
itself by configuring `LocalTasks`.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    LocalTasks = @(
        'Tasks/ValidateTaskDocs.ps1'
        'Tasks/CheckGeneratedFiles.ps1'
    )
}
```

When `LocalTasks` is configured, Plumber dot-sources each file, creates a
`Local` task group, adds each local task as an optional dependency of `Local`,
and adds `Local` as an optional dependency of `Validate`.

When `LocalTasks` is empty or omitted, Plumber does not load the `Local` group.

## Task Names

Plumber uses the local task file name as the task name:

```text
Tasks/ValidateTaskDocs.ps1 -> ValidateTaskDocs
```

The local task file should register a matching Invoke-Build task:

```powershell
Add-BuildTask -Name ValidateTaskDocs -Jobs {
    # local validation
}
```

`LocalTasks` paths can be absolute or relative to the build root.

## Excluding Local Tasks

`ExcludeTasks` works for the `Local` group and individual local tasks.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    LocalTasks = @(
        'Tasks/ValidateTaskDocs.ps1'
        'Tasks/CheckGeneratedFiles.ps1'
    )
    ExcludeTasks = @('ValidateTaskDocs')
}
```

Exclude all local tasks by excluding the group:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    LocalTasks = @(
        'Tasks/ValidateTaskDocs.ps1'
        'Tasks/CheckGeneratedFiles.ps1'
    )
    ExcludeTasks = @('Local')
}
```
