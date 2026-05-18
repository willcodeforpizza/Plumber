function Invoke-PlumberFunctionFiles {
    <#
        .SYNOPSIS
        Runs the FunctionFiles task body.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Task body function matches the FunctionFiles task name.'
    )]
    [CmdletBinding()]
    param ()

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
        $relativePath = [System.IO.Path]::GetRelativePath($BuildRoot, $moduleFile.FullName).
            Replace([System.IO.Path]::DirectorySeparatorChar, '/').
            Replace([System.IO.Path]::AltDirectorySeparatorChar, '/')
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
