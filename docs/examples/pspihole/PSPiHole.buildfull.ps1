<#
    .SYNOPSIS
    Full validation build for the PSServiceDesk demo module.

    .DESCRIPTION
    Provides an Invoke-Build pipeline that groups validation into the categories used by the
    Stop Breaking Production presentation.
#>
[CmdletBinding()]
param ()

$script:moduleRoot        = $PSScriptRoot
$script:moduleName        = 'PSPiHole'
$script:manifestPath      = Join-Path -Path $script:moduleRoot -ChildPath "$script:moduleName.psd1"
$script:testRoot          = Join-Path -Path $script:moduleRoot -ChildPath 'Tests'
$script:coverageThreshold = 80

function Get-Manifest {
    <#
        .SYNOPSIS
        Gets the module manifest as a hashtable.
    #>

    [CmdletBinding()]
    param ()

    Import-PowerShellDataFile -Path $script:manifestPath
}

function Get-SourceFile {
    <#
        .SYNOPSIS
        Gets PowerShell source files that should be included in code coverage.
    #>

    [CmdletBinding()]
    param ()

    $sourceDirectories = @(
        (Join-Path -Path $script:moduleRoot -ChildPath 'Public'),
        (Join-Path -Path $script:moduleRoot -ChildPath 'Private')
    )

    foreach ($directory in $sourceDirectories) {
        Get-ChildItem -Path $directory -Filter '*.ps1' -Recurse -File
    }

    Get-Item -Path (Join-Path -Path $script:moduleRoot -ChildPath "$script:moduleName.psm1")
}

function Get-CoveragePercent {
    <#
        .SYNOPSIS
        Gets a coverage percentage from a Pester result object.

        .OUTPUTS
        System.Double
    #>

    [CmdletBinding()]
    [OutputType([double])]
    param (
        # Pester result object returned by Invoke-Pester -PassThru
        [Parameter(Mandatory)]
        [psobject]
        $PesterResult
    )

    if ($null -eq $PesterResult.CodeCoverage) {
        throw 'Pester did not return code coverage information.'
    }

    if ($null -ne $PesterResult.CodeCoverage.CoveragePercent) {
        [double]$PesterResult.CodeCoverage.CoveragePercent
        return
    }

    if ($null -ne $PesterResult.CodeCoverage.CommandsAnalyzed) {
        $commandsAnalyzed = [double]$PesterResult.CodeCoverage.CommandsAnalyzed.Count
        $commandsMissed = [double]$PesterResult.CodeCoverage.MissedCommands.Count

        if ($commandsAnalyzed -eq 0) {
            throw 'Pester analyzed zero commands for coverage.'
        }

        (($commandsAnalyzed - $commandsMissed) / $commandsAnalyzed) * 100
        return
    }

    throw 'Unable to read code coverage percentage from the Pester result.'
}

function Test-PSServiceDeskYamlFile {
    <#
        .SYNOPSIS
        Performs lightweight YAML syntax validation for demo config files.
    #>

    [CmdletBinding()]
    param (
        # YAML file to validate
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    if ($null -ne (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        Get-Content -Path $Path -Raw | ConvertFrom-Yaml > $null
        return
    }

    $lineNumber = 0
    $blockScalarIndent = $null
    foreach ($line in Get-Content -Path $Path) {
        $lineNumber++

        if ($line -match '\t') {
            throw "YAML file '$Path' contains a tab on line $lineNumber."
        }

        if ($line -match '^\s*$' -or $line -match '^\s*#') {
            continue
        }

        $leadingSpaceCount = ($line.Length - $line.TrimStart(' ').Length)
        if ($null -ne $blockScalarIndent) {
            if ($leadingSpaceCount -gt $blockScalarIndent) {
                continue
            }

            $blockScalarIndent = $null
        }

        if ($leadingSpaceCount % 2 -ne 0) {
            throw "YAML file '$Path' has odd indentation on line $lineNumber."
        }

        if ($line -notmatch '^\s*(-\s+)?[A-Za-z][A-Za-z0-9_-]*:\s*.*$' -and
            $line -notmatch '^\s*-\s+[A-Za-z0-9_-]+\s*$') {
            throw "YAML file '$Path' has unsupported syntax on line $lineNumber."
        }

        if ($line -match ':\s*[|>]\s*$') {
            $blockScalarIndent = $leadingSpaceCount
        }
    }
}

Add-BuildTask . Validate

Add-BuildTask Validate CodeQuality, ReleaseHygiene, Content, ModuleConventions

Add-BuildTask CodeQuality Analyze, Test, Coverage

Add-BuildTask ReleaseHygiene ValidateModuleVersion, ValidateChangelog

Add-BuildTask Content ValidateJson, ValidateYaml

Add-BuildTask ModuleConventions ValidateLayout, ValidateExports, ValidateNaming

Add-BuildTask Analyze {
    $results = Invoke-ScriptAnalyzer -Path $script:moduleRoot -IncludeDefaultRules -Recurse

    if ($results) {
        $results | Format-Table -AutoSize
        throw 'PSScriptAnalyzer reported issues.'
    }
}

Add-BuildTask Test {
    if ($null -eq (Get-Command -Name New-PesterConfiguration -ErrorAction SilentlyContinue)) {
        throw 'Pester 5 is required because these tests use Pester 5 syntax.'
    }

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = $script:testRoot
    $configuration.Run.PassThru = $true
    $configuration.Output.Verbosity = 'Normal'
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @(Get-SourceFile | Select-Object -ExpandProperty FullName)

    $result = Invoke-Pester -Configuration $configuration

    if ($result.FailedCount -gt 0) {
        throw "Pester reported $($result.FailedCount) failing test(s)."
    }

    $script:pesterResult = $result
}

Add-BuildTask Coverage -Jobs 'Test', {
    $result = $script:pesterResult
    $coveragePercent = Get-CoveragePercent -PesterResult $result
    Write-Information -MessageData ('Code coverage: {0:N2}%' -f $coveragePercent) -InformationAction Continue

    if ($coveragePercent -lt $script:coverageThreshold) {
        throw "Code coverage is below $script:coverageThreshold%."
    }
}

Add-BuildTask ValidateModuleVersion {
    $publishedModule = Find-Module -Name $script:moduleName -ErrorAction SilentlyContinue
    if ($null -eq $publishedModule) {
        Write-Warning 'Module not published - not validating version.'
        return
    }

    $manifest = Get-Manifest
    $currentVersion = [version]$manifest.ModuleVersion
    $publishedVersion = [version]$publishedModule.Version

    if ($currentVersion -le $publishedVersion) {
        throw "Module version $currentVersion must be greater than published version $publishedVersion."
    }
}

Add-BuildTask ValidateChangelog {
    $manifest = Get-Manifest
    $currentVersion = [version]$manifest.ModuleVersion
    $changelogPath = Join-Path -Path $script:moduleRoot -ChildPath 'CHANGELOG.md'

    if (-not (Test-Path -Path $changelogPath)) {
        throw 'CHANGELOG.md is missing.'
    }

    $versionHeading = '^## ' + [regex]::Escape($currentVersion.ToString()) + '$'
    if (-not (Select-String -Path $changelogPath -Pattern $versionHeading -Quiet)) {
        throw "CHANGELOG.md must contain a heading in the format ## $currentVersion."
    }
}

Add-BuildTask ValidateJson {
    $jsonFiles = Get-ChildItem -Path $script:moduleRoot -Filter '*.json' -Recurse -File

    foreach ($jsonFile in $jsonFiles) {
        Get-Content -Path $jsonFile.FullName -Raw | ConvertFrom-Json > $null
    }
}

Add-BuildTask ValidateYaml {
    $yamlFiles = Get-ChildItem -Path $script:moduleRoot -Include '*.yaml', '*.yml' -Recurse -File

    foreach ($yamlFile in $yamlFiles) {
        Test-PSServiceDeskYamlFile -Path $yamlFile.FullName
    }
}

Add-BuildTask ValidateLayout {
    foreach ($requiredDirectory in @('Public', 'Private', 'Tests')) {
        $path = Join-Path -Path $script:moduleRoot -ChildPath $requiredDirectory
        if (-not (Test-Path -Path $path -PathType Container)) {
            throw "Required directory '$requiredDirectory' is missing."
        }
    }

    $psm1Path = (Join-Path -Path $script:moduleRoot -ChildPath "$script:moduleName.psm1")
    if (Select-String -Path $psm1Path -Pattern '^function ') {
        throw "$script:moduleName.psm1 should only import split function files."
    }
}

Add-BuildTask ValidateExports {
    $manifest = Get-Manifest
    $publicFolder = (Join-Path -Path $script:moduleRoot -ChildPath 'Public')
    $publicFunctionNames = Get-ChildItem -Path $publicFolder -Filter '*.ps1' |
        Select-Object -ExpandProperty BaseName
    $exportedFunctionNames = @($manifest.FunctionsToExport)

    $missingExports = $publicFunctionNames | Where-Object {$PSItem -notin $exportedFunctionNames}
    $extraExports = $exportedFunctionNames | Where-Object {$PSItem -notin $publicFunctionNames}

    if ($missingExports) {
        throw ('Manifest is missing public exports: ' + ($missingExports -join ', '))
    }

    if ($extraExports) {
        throw ('Manifest exports functions without matching Public files: ' + ($extraExports -join ', '))
    }
}

Add-BuildTask ValidateNaming {
    $functionDirectories = @('Public', 'Private') | ForEach-Object {
        Join-Path -Path $script:moduleRoot -ChildPath $PSItem
    }
    $functionFiles = Get-ChildItem -Path $functionDirectories -Filter '*.ps1' -Recurse -File

    foreach ($functionFile in $functionFiles) {
        $functionName = $functionFile.BaseName
        $functionDefinitionPattern = '^\s*function\s+' + [regex]::Escape($functionName) + '\b'
        $selectStringParams = @{
            Path    = $functionFile.FullName
            Pattern = $functionDefinitionPattern
            Quiet   = $true
        }
        $functionDefinition = Select-String @selectStringParams

        if (-not $functionDefinition) {
            throw "File '$($functionFile.Name)' must define function '$functionName'."
        }
    }
}
