function Invoke-PlumberPublicFunctions {
    <#
        .SYNOPSIS
        Runs the PublicFunctions task body.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseSingularNouns',
        '',
        Justification = 'Task body function matches the PublicFunctions task name.'
    )]
    [CmdletBinding()]
    param ()

    $exportedFunctions = @($script:psd1.FunctionsToExport)
    $publicRoot = Join-Path $BuildRoot 'Public'
    $pathComparison = Get-PlumberPathStringComparison
    $nonPublicRoots = $script:moduleFolders |
        Where-Object {-not $_.Equals($publicRoot, $pathComparison)}
    $publicFiles = if (Test-Path $publicRoot) {
        @(Get-ChildItem $publicRoot -File -Filter '*.ps1')
    } else {
        @()
    }
    $nonPublicFiles = foreach ($nonPublicRoot in $nonPublicRoots) {
        if (Test-Path $nonPublicRoot) {
            Get-ChildItem $nonPublicRoot -File -Filter '*.ps1'
        }
    }

    $publicFunctionNames = @($publicFiles | Select-Object -ExpandProperty BaseName)
    $failures = foreach ($publicFile in $publicFiles) {
        if ($publicFile.BaseName -notin $exportedFunctions) {
            "$($publicFile.BaseName) is not in FunctionsToExport"
        }

        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $publicFile.FullName,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors) {
            "$($publicFile.Name) could not be parsed"
            continue
        }

        $functionNames = @($ast.FindAll(
                {
                    param ($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                },
                $true
            ) | Select-Object -ExpandProperty Name)
        if ($publicFile.BaseName -notin $functionNames) {
            "$($publicFile.Name) does not define function $($publicFile.BaseName)"
        }
    }

    $failures += foreach ($exportedFunction in $exportedFunctions) {
        if ($exportedFunction -notin $publicFunctionNames) {
            "$exportedFunction is exported but Public/$exportedFunction.ps1 was not found"
        }
    }

    $failures += foreach ($nonPublicFile in $nonPublicFiles) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $nonPublicFile.FullName,
            [ref]$tokens,
            [ref]$parseErrors
        )
        if ($parseErrors) {
            "$($nonPublicFile.Name) could not be parsed"
            continue
        }

        $nonPublicFunctionNames = @($ast.FindAll(
                {
                    param ($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                },
                $true
            ) | Select-Object -ExpandProperty Name)
        foreach ($nonPublicFunctionName in $nonPublicFunctionNames) {
            if ($nonPublicFunctionName -in $exportedFunctions) {
                $relativePath = [System.IO.Path]::GetRelativePath(
                    $BuildRoot,
                    $nonPublicFile.FullName
                ).
                    Replace([System.IO.Path]::DirectorySeparatorChar, '/').
                    Replace([System.IO.Path]::AltDirectorySeparatorChar, '/')
                "$nonPublicFunctionName is exported from $relativePath"
            }
        }
    }

    if ($failures) {
        Write-Error ($failures -join (', ' + [Environment]::NewLine))
    }
}
