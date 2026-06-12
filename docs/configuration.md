# Configuration

Plumber configuration lives in the hashtable passed to
`Get-PlumberTaskLoader` from a repository build file.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

Plumber merges that hashtable with its defaults before tasks are loaded. The
merged config is validated immediately, so mistakes fail before the task graph
runs.

## Validation

Plumber validates built-in configuration at task-loader time. Validation catches:

- unknown top-level keys
- unknown built-in task names
- unknown built-in task settings
- invalid value types
- invalid enum values
- out-of-range integer values
- malformed `JSONSchema` schema mappings

Errors are reported together with dotted config paths. When a typo is close to a
known key, Plumber includes a suggestion.

Example invalid config:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    FileScope = 'Sometimes'
    Tasks     = @{
        LineLenght = @{
            MaxLength = 80
        }
    }
}
```

Example error shape:

```text
Plumber config failed validation:
- FileScope: Expected one of 'All', 'Changed', got 'Sometimes'
- Tasks.LineLenght is not a known task. Did you mean LineLength?
```

Plumber validates its built-in config surface only. Local task config bodies are
left permissive so project-specific tasks can define their own settings without
Plumber needing to know their shape.

## Global Settings

### ModuleManifest

`ModuleManifest` points to the module manifest used by module convention and
release hygiene tasks.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = 'MyModule.psd1'
}
```

### IncludeModuleFolders

`IncludeModuleFolders` adds extra module source folders to the default `Public`
and `Private` folders. Source-root tasks such as `PesterUnit` code coverage and
`FunctionFiles` use these folders.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    IncludeModuleFolders = @('TaskFunctions')
}
```

### ExcludeDirectories

`ExcludeDirectories` lists additional directory names that Plumber's shared
file discovery skips entirely. `.git` is always excluded and does not need to
be listed. Names match path segments at any depth under the build root.

Use it to exclude build artifact directories, such as the `out` folder a local
Plumber.Release build writes:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    ExcludeDirectories = @('out')
}
```

Like `FileScope`, this applies only to tasks that use `Get-PlumberTaskFile`.
Use `Tasks.<Task>.Exclude` for task-scoped exclusions of files that other tasks
should still see.

### FileScope

`FileScope` controls which files are returned by Plumber's shared file
discovery. The default is `All`.

Set `FileScope` to `Changed` to validate only files changed in git. This includes
staged changes, unstaged changes and untracked files. Deleted files are ignored.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    FileScope = 'Changed'
}
```

For pull request validation, combine `FileScope = 'Changed'` with `DiffBase`:

```powershell
. (Get-PlumberTaskLoader) -Config @{
    FileScope = 'Changed'
    DiffBase  = 'origin/main'
}
```

Changed-file scope applies only to tasks that use `Get-PlumberTaskFile`, such as
`PSScriptAnalyzer`, `Backticks`, `LineLength`, `ToDo`, `JSON`, `JSONSchema` and
`YAML`. Pester and module-wide checks still run normally.

### DiffBase

`DiffBase` sets the git comparison base used when `FileScope` is `Changed`.
Plumber compares `DiffBase...HEAD`, then also includes staged, unstaged and
untracked files.

## Task Settings

### Tasks.<Task>.RunWhen

`Tasks.<Task>.RunWhen` controls when a task runs. `<Task>` can be a built-in
task, a group task, or the file stem of a local task. Supported values are:

- `Always` - run whenever the task is selected. This is the default.
- `OnRelease` - run only when `PLUMBER_RELEASE_INTENT=true`.
- `Never` - never run the task.

Skipped tasks are registered as explicit skip tasks so direct task invocation
explains why validation did not run.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        ModuleVersion = @{
            RunWhen = 'OnRelease'
        }
        ToDo = @{
            RunWhen = 'Never'
        }
        Content = @{
            RunWhen = 'Never'
        }
    }
}
```

`Tasks.Exclude` has been removed. Use `Tasks.<Task>.RunWhen = 'Never'`
instead.

### Tasks.Local

`Tasks.Local` adds project-specific validation tasks to the `Validate` graph.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        Local = @('Tasks/ValidateTaskDocs.ps1')
    }
}
```

If `Tasks.Local` includes `Tasks/ValidateTaskDocs.ps1`, Plumber allows a
matching `Tasks.ValidateTaskDocs` config block but does not validate that block's
contents.

See [Local tasks](local-tasks.md) for local task authoring details.

### Tasks.&lt;Task&gt;.Exclude

`Tasks.<Task>.Exclude` is task-scoped. A file excluded from one task can still be
used by another task.

```powershell
. (Get-PlumberTaskLoader) -Config @{
    Tasks = @{
        PSScriptAnalyzer = @{
            Exclude = @('Tests/Assets/TaskHelp/InvalidPowerShell.ps1')
        }
    }
}
```

Patterns use PowerShell wildcard matching against repository-relative paths
normalized with `/`.

Review the [task index](tasks/index.md) for each task's supported settings.
