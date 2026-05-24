function Test-PlumberConfig {
    <#
        .SYNOPSIS
        Validates Plumber task loader configuration.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $Config
    )

    $rules = Get-PlumberConfigRule
    $topLevelKeys = @(
        'ModuleManifest'
        'DiffBase'
        'FileScope'
        'IncludeModuleFolders'
        'BuildRoot'
        'Tasks'
    )
    $taskKeys = @(
        $rules.Keys |
            Where-Object {$_ -like 'Tasks.*.*'} |
                ForEach-Object {($_ -split '\.')[1]}
        'Local'
    ) | Sort-Object -Unique
    $errors = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $Config.Keys) {
        if ($key -notin $topLevelKeys) {
            $messageSplat = @{
                Path        = $key
                Kind        = 'top-level key'
                AllowedName = $topLevelKeys
            }
            $errors.Add((Get-PlumberConfigUnknownKeyMessage @messageSplat))
            continue
        }

        if ($key -ne 'Tasks' -and $rules.ContainsKey($key)) {
            $message = Invoke-PlumberConfigValidator -Value $Config[$key] -Rule $rules[$key]
            if ($message) {
                $errors.Add("$key`: $message")
            }
        }
    }

    if ($Config.Tasks -isnot [hashtable]) {
        $errors.Add('Tasks: Expected hashtable')
    } else {
        $localTaskName = @(
            foreach ($localTaskPath in @($Config.Tasks.Local)) {
                if ($localTaskPath) {
                    [IO.Path]::GetFileNameWithoutExtension($localTaskPath)
                }
            }
        )
        foreach ($taskKey in $Config.Tasks.Keys) {
            $isLocalTask = $taskKey -in $localTaskName
            if ($taskKey -notin $taskKeys) {
                if (-not $isLocalTask) {
                    $path = "Tasks.$taskKey"
                    $allowedTaskName = @($taskKeys) + @($localTaskName)
                    $messageSplat = @{
                        Path        = $path
                        Kind        = 'task'
                        AllowedName = $allowedTaskName
                    }
                    $errors.Add((Get-PlumberConfigUnknownKeyMessage @messageSplat))
                    continue
                }
            }

            if ($taskKey -eq 'Local') {
                $rulePath = "Tasks.$taskKey"
                $message = Invoke-PlumberConfigValidator -Value $Config.Tasks[$taskKey] -Rule $rules[$rulePath]
                if ($message) {
                    $errors.Add("$rulePath`: $message")
                }
                continue
            }

            if ($Config.Tasks[$taskKey] -isnot [hashtable]) {
                $errors.Add("Tasks.$taskKey`: Expected hashtable")
                continue
            }

            $settingKeys = if ($isLocalTask) {
                @('RunWhen')
            } else {
                @(
                    $rules.Keys |
                        Where-Object {$_ -like "Tasks.$taskKey.*"} |
                            ForEach-Object {($_ -split '\.')[2]}
                )
            }
            foreach ($settingKey in $Config.Tasks[$taskKey].Keys) {
                if ($isLocalTask -and $settingKey -ne 'RunWhen') {
                    continue
                }

                if ($settingKey -notin $settingKeys) {
                    $path = "Tasks.$taskKey.$settingKey"
                    $messageSplat = @{
                        Path        = $path
                        Kind        = 'setting'
                        AllowedName = $settingKeys
                    }
                    $errors.Add((Get-PlumberConfigUnknownKeyMessage @messageSplat))
                    continue
                }

                $rulePath = "Tasks.$taskKey.$settingKey"
                $validatorRulePath = if ($isLocalTask -and $settingKey -eq 'RunWhen') {
                    'Tasks.CodeQuality.RunWhen'
                } else {
                    $rulePath
                }
                $validatorSplat = @{
                    Value = $Config.Tasks[$taskKey][$settingKey]
                    Rule  = $rules[$validatorRulePath]
                }
                $message = Invoke-PlumberConfigValidator @validatorSplat
                if ($message) {
                    $errors.Add("$rulePath`: $message")
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Plumber config failed validation:`n- $($errors -join "`n- ")"
    }
}
