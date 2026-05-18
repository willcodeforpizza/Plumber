<#
    .SYNOPSIS
    Validates all public functions are declared in the PSD1.

    .DESCRIPTION
    Checks files under `Public` and fails when a public function file name is
    not listed in the manifest `FunctionsToExport` value, an exported function
    has no matching public file, a public file does not define a matching
    function, or a private function is exported.

    .GROUP
    ModuleConventions

    .CONFIGURATION
    `ModuleManifest` controls which module manifest supplies
    `FunctionsToExport`.

    ### Example

    ```powershell
    . (Get-PlumberTaskLoader) -Config @{
        ModuleManifest = 'MyModule.psd1'
    }
    ```

    .RUN
    ```powershell
    Invoke-Plumber -Task PublicFunctions
    ```

    .PASS
    ```powershell
    FunctionsToExport = @('Get-Thing')
    ```

    .FAIL
    ```powershell
    FunctionsToExport = @()
    ```
#>
Add-BuildTask -Name PublicFunctions -Jobs SetVariables, {
    $exportedFunctions = @($script:psd1.FunctionsToExport)
    $publicRoot = Join-Path $BuildRoot 'Public'
    $nonPublicRoots = $script:moduleFolders |
        Where-Object {-not $_.Equals($publicRoot, [System.StringComparison]::OrdinalIgnoreCase)}
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
