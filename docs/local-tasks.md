# Local Tasks

Plumber's built-in task graph stays focused on shared validation tasks. Projects
can add repository-specific validation without adding those tasks to Plumber
itself by configuring `Tasks.Local`.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks = @{
        Local = @(
            'Tasks/ValidateTaskDocs.ps1'
            'Tasks/CheckGeneratedFiles.ps1'
        )
    }
}
```

When `Tasks.Local` is configured, Plumber dot-sources each file, creates a
`Local` task group, adds each local task as an optional dependency of `Local`,
and adds `Local` as an optional dependency of `Validate`.

When `Tasks.Local` is empty or omitted, Plumber does not load the `Local` group.

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

`Tasks.Local` paths can be absolute or relative to the build root.

## Excluding Local Tasks

`Tasks.Exclude` works for the `Local` group and individual local tasks.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks = @{
        Local = @(
            'Tasks/ValidateTaskDocs.ps1'
            'Tasks/CheckGeneratedFiles.ps1'
        )
        Exclude = @('ValidateTaskDocs')
    }
}
```

Exclude all local tasks by excluding the group:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks = @{
        Local = @(
            'Tasks/ValidateTaskDocs.ps1'
            'Tasks/CheckGeneratedFiles.ps1'
        )
        Exclude = @('Local')
    }
}
```
