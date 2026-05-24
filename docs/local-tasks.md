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

## Controlling Local Task Enforcement

Local tasks support the same `EnforceWhen` task policy as built-in tasks. Add a
config block named after the local task file stem:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
    Tasks = @{
        Local = @(
            'Tasks/ValidateTaskDocs.ps1'
            'Tasks/CheckGeneratedFiles.ps1'
        )
        ValidateTaskDocs = @{
            EnforceWhen = 'Never'
        }
    }
}
```

Use `EnforceWhen = 'OnRelease'` to run a local task only when
`PLUMBER_RELEASE_INTENT=true`.
