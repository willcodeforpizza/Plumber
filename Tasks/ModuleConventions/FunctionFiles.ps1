<#
    .SYNOPSIS
    Validates PowerShell function files contain one matching function.

    .DESCRIPTION
    Checks files under `Public` and `Private` and fails when a PowerShell
    function file contains no function, more than one function, cannot be
    parsed, or defines a function whose name does not match the file name.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `FunctionFiles.Exclude` excludes repository-relative paths from validation.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        Tasks = @{
            FunctionFiles = @{
                Exclude = @('Private/Generated/*.ps1')
            }
        }
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task FunctionFiles
    ```

    .PASS
    ```powershell
    # Public/Get-Thing.ps1
    function Get-Thing {
    }
    ```

    .FAIL
    ```powershell
    # Private/Helpers.ps1
    function Get-Thing {
    }

    function Set-Thing {
    }
    ```
#>
Add-BuildTask -Name FunctionFiles -Jobs SetVariables, {
    $moduleFiles = foreach ($moduleFolder in $script:moduleFolders) {
        if (-not (Test-Path $moduleFolder)) {
            continue
        }

        Get-PlumberTaskFile -Task FunctionFiles -Extension '.ps1' -Path $moduleFolder
    }

    $failures = foreach ($moduleFile in $moduleFiles) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $moduleFile.FullName,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $relativePath = [System.IO.Path]::GetRelativePath($BuildRoot, $moduleFile.FullName)
        if ($parseErrors) {
            "$relativePath could not be parsed"
            continue
        }

        $functions = @($ast.FindAll(
                {
                    param ($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                },
                $true
            ))

        if ($functions.Count -ne 1) {
            "$relativePath defines $($functions.Count) functions; expected 1"
            continue
        }

        $functionName = $functions[0].Name
        if ($functionName -cne $moduleFile.BaseName) {
            "$relativePath defines function $functionName; expected $($moduleFile.BaseName)"
        }
    }

    if ($failures) {
        Write-Error ($failures -join [Environment]::NewLine)
    }
}
