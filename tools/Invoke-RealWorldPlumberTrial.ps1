<#
    .SYNOPSIS
    Runs a one-off real-world Plumber trial against popular PowerShell Gallery modules.

    .DESCRIPTION
    This script is an ad-hoc learning harness, not part of Plumber's public API.
    It downloads popular non-vendor PowerShell Gallery modules into an ignored
    out/ workspace, generates a minimal Plumber build file for each package, and
    runs strict default Validate so the out-of-box experience is visible.
#>
[CmdletBinding()]
param (
    [int]
    $ModuleCount = 20,

    [int]
    $CandidateCount = 250,

    [string]
    $WorkspacePath = (Join-Path $PSScriptRoot '../out/RealWorldTrial'),

    [string]
    $Task = 'Validate',

    [switch]
    $RefreshDownloads
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$vendorNamePatterns = @(
    '^Microsoft(\.|$)'
    '^Az(\.|$)'
    '^Azure(\.|$)'
    '^AWS(\.|$)'
    '^AWS\.Tools(\.|$)'
    '^AWSPowerShell'
    '^VMware(\.|$)'
    '^ExchangeOnlineManagement$'
    '^SqlServer$'
    '^PnP\.PowerShell$'
    '^MicrosoftGraph$'
    '^MSAL\.PS$'
)

$vendorAuthorPatterns = @(
    'Microsoft'
    'Amazon'
    'AWS'
    'VMware'
)

function Test-VendorModule {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Module
    )

    foreach ($pattern in $vendorNamePatterns) {
        if ($Module.Name -match $pattern) {
            return $true
        }
    }

    foreach ($pattern in $vendorAuthorPatterns) {
        if ($Module.Author -match $pattern) {
            return $true
        }
    }

    return $false
}

function Get-GalleryCandidate {
    param (
        [int]
        $Top,

        [int]
        $PageSize = 100
    )

    $skip = 0
    while ($skip -lt $Top) {
        $currentTop = [Math]::Min($PageSize, $Top - $skip)
        $uri = 'https://www.powershellgallery.com/api/v2/Packages()' +
            '?$filter=IsLatestVersion%20eq%20true' +
            '&$orderby=DownloadCount%20desc' +
            "&`$top=$currentTop" +
            "&`$skip=$skip"

        $response = @(Invoke-RestMethod -Uri $uri -Headers @{
            Accept = 'application/atom+xml'
        })

        if ($response.Count -eq 0) {
            break
        }

        foreach ($entry in $response) {
            $properties = $entry.properties
            $name = ConvertFrom-GalleryXmlValue $properties.Id
            $version = ConvertFrom-GalleryXmlValue $properties.Version
            [pscustomobject]@{
                Name          = $name
                Version       = $version
                Author        = ConvertFrom-GalleryXmlValue $properties.Authors
                DownloadCount = [int64](ConvertFrom-GalleryXmlValue $properties.DownloadCount)
                GalleryUrl    = "https://www.powershellgallery.com/packages/$name/$version"
            }
        }

        if ($response.Count -lt $currentTop) {
            break
        }

        $skip += $response.Count
    }
}

function ConvertFrom-GalleryXmlValue {
    param (
        $Value
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [System.Xml.XmlNode]) {
        return $Value.InnerText
    }

    return [string]$Value
}

function ConvertTo-TrialErrorArray {
    param (
        [AllowNull()]
        [string]
        $ErrorText
    )

    if ([string]::IsNullOrWhiteSpace($ErrorText)) {
        return @()
    }

    return @(
        $ErrorText -split '\r?\n' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )
}

function ConvertTo-TrialJsonResult {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Result
    )

    $tasks = @(
        foreach ($taskResult in $Result.Tasks) {
            [pscustomobject]@{
                Name   = $taskResult.Name
                Status = $taskResult.Status
                Errors = [string[]]@(ConvertTo-TrialErrorArray -ErrorText $taskResult.Error)
            }
        }
    )

    $failures = @($tasks | Where-Object { $_.Status -eq 'Failed' })

    [pscustomobject]@{
        Success  = [bool]$Result.Success
        Passed   = [int]$Result.Passed
        Failed   = [int]$Result.Failed
        Tasks    = $tasks
        Failures = $failures
    }
}

function Format-TrialFailureSummary {
    param (
        [AllowNull()]
        [object[]]
        $Failure
    )

    return @(
        foreach ($item in @($Failure)) {
            $errorCount = @($item.Errors).Count
            "$($item.Name) ($errorCount)"
        }
    ) -join ', '
}

function Save-GalleryPackage {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Module,

        [Parameter(Mandatory)]
        [string]
        $DestinationPath
    )

    $packagePath = Join-Path $DestinationPath "$($Module.Name).$($Module.Version).nupkg"
    if (Test-Path -LiteralPath $packagePath) {
        Write-Verbose "Using existing package $packagePath"
        return $packagePath
    }

    $packageUri = "https://www.powershellgallery.com/api/v2/package/$($Module.Name)/$($Module.Version)"
    Invoke-WebRequest -Uri $packageUri -OutFile $packagePath
    return $packagePath
}

function Expand-GalleryPackage {
    param (
        [Parameter(Mandatory)]
        [string]
        $PackagePath,

        [Parameter(Mandatory)]
        [string]
        $DestinationPath
    )

    if (Test-Path -LiteralPath $DestinationPath) {
        Remove-Item -LiteralPath $DestinationPath -Recurse -Force
    }

    New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    Expand-Archive -LiteralPath $PackagePath -DestinationPath $DestinationPath -Force
}

function Get-TrialManifest {
    param (
        [Parameter(Mandatory)]
        [string]
        $PackageRoot,

        [Parameter(Mandatory)]
        [string]
        $ModuleName
    )

    $preferred = Get-ChildItem -LiteralPath $PackageRoot -Recurse -File -Filter "$ModuleName.psd1" |
        Where-Object {
            $_.FullName -notmatch '\\_(rels|metadata)\\' -and
            $_.FullName -notmatch '\\package\\'
        } |
        Sort-Object { $_.FullName.Length } |
        Select-Object -First 1

    if ($preferred) {
        return $preferred
    }

    return Get-ChildItem -LiteralPath $PackageRoot -Recurse -File -Filter '*.psd1' |
        Where-Object {
            $_.FullName -notmatch '\\_(rels|metadata)\\' -and
            $_.FullName -notmatch '\\package\\'
        } |
        Sort-Object { $_.FullName.Length } |
        Select-Object -First 1
}

function New-TrialBuildFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        ''
    )]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $Manifest
    )

    $buildFile = Join-Path $Manifest.Directory.FullName 'PlumberTrial.build.ps1'
    @"
. (Get-PlumberTaskLoader) -Config @{
    ModuleManifest = '$($Manifest.Name)'
}
"@ | Set-Content -LiteralPath $buildFile -Encoding utf8

    return $buildFile
}

function Invoke-ModuleTrial {
    param (
        [Parameter(Mandatory)]
        [pscustomobject]
        $Module,

        [Parameter(Mandatory)]
        [string]
        $DownloadPath,

        [Parameter(Mandatory)]
        [string]
        $ExtractPath,

        [Parameter(Mandatory)]
        [string]
        $LogPath,

        [Parameter(Mandatory)]
        [string]
        $Task
    )

    $started = Get-Date
    $classification = 'Expected module failure'
    $notes = ''
    $success = $false
    $exitMessage = ''
    $manifestPath = ''
    $jsonPath = Join-Path $LogPath "$($Module.Name).json"
    $errorPath = Join-Path $LogPath "$($Module.Name).error.txt"
    $failedTasks = ''
    $passedCount = 0
    $failedCount = 0
    $parsedResult = $null

    try {
        $packagePath = Save-GalleryPackage -Module $Module -DestinationPath $DownloadPath
        $moduleExtractPath = Join-Path $ExtractPath $Module.Name
        Expand-GalleryPackage -PackagePath $packagePath -DestinationPath $moduleExtractPath

        $manifest = Get-TrialManifest -PackageRoot $moduleExtractPath -ModuleName $Module.Name
        if (-not $manifest) {
            $classification = 'Unsupported layout'
            $notes = 'No module manifest found in Gallery package.'
            throw 'No module manifest found.'
        }

        $manifestPath = $manifest.FullName
        $buildFile = New-TrialBuildFile -Manifest $manifest
        $moduleRoot = $manifest.Directory.FullName

        Push-Location $moduleRoot
        try {
            Invoke-Plumber -BuildFile $buildFile -Task $Task -OutputMode Json > $jsonPath 2> $errorPath
        } catch {
            $exitMessage = $_.Exception.Message
        } finally {
            Pop-Location
        }

        if ((Test-Path -LiteralPath $jsonPath) -and (Get-Item -LiteralPath $jsonPath).Length -gt 0) {
            $parsedResult = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
            $parsedResult = ConvertTo-TrialJsonResult -Result $parsedResult
            $parsedResult | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding utf8

            $success = [bool]$parsedResult.Success
            $passedCount = [int]$parsedResult.Passed
            $failedCount = [int]$parsedResult.Failed
            $failedTasks = Format-TrialFailureSummary -Failure $parsedResult.Failures

            if ($success) {
                $classification = 'Pass'
                $notes = 'Strict Validate passed.'
            } else {
                $classification = 'Expected module failure'
                $notes = 'Review JSON failures and classify manually.'
            }
        } else {
            $classification = 'Plumber defect'
            $notes = 'No JSON output was produced. Review error file.'
        }
    } catch {
        if (-not $exitMessage) {
            $exitMessage = $_.Exception.Message
        }
    }

    [pscustomobject]@{
        Name           = $Module.Name
        Version        = $Module.Version
        Author         = $Module.Author
        DownloadCount  = $Module.DownloadCount
        GalleryUrl     = $Module.GalleryUrl
        ManifestPath   = $manifestPath
        JsonPath       = $jsonPath
        ErrorPath      = $errorPath
        Success        = $success
        Passed         = $passedCount
        Failed         = $failedCount
        FailedTasks    = $failedTasks
        Classification = $classification
        Notes          = $notes
        ExitMessage    = $exitMessage
        Started        = $started.ToString('o')
        Finished       = (Get-Date).ToString('o')
    }
}

function New-TrialMarkdown {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions',
        ''
    )]
    param (
        [Parameter(Mandatory)]
        [object[]]
        $Result,

        [Parameter(Mandatory)]
        [string]
        $Path
    )

    $lines = @(
        '# Real-world Plumber trial'
        ''
        "Generated: $(Get-Date -Format o)"
        ''
        '| Module | Version | Downloads | Result | Failed tasks | JSON | Notes |'
        '| --- | --- | ---: | --- | --- | --- | --- |'
    )

    foreach ($item in $Result) {
        $status = if ($item.Success) { 'Pass' } else { 'Fail' }
        $notes = ($item.Notes -replace '\|', '\|')
        $failedTasks = ($item.FailedTasks -replace '\|', '\|')
        $jsonName = Split-Path $item.JsonPath -Leaf
        $lines += @(
            "| [$($item.Name)]($($item.GalleryUrl)) | $($item.Version) | " +
            "$($item.DownloadCount) | $status | $failedTasks | " +
            "[json](logs/$jsonName) | $notes |"
        ) -join ''
    }

    $lines | Set-Content -LiteralPath $Path -Encoding utf8
}

$workspace = Resolve-Path -LiteralPath (New-Item -Path $WorkspacePath -ItemType Directory -Force).FullName
$downloadPath = Join-Path $workspace 'downloads'
$extractPath = Join-Path $workspace 'packages'
$logPath = Join-Path $workspace 'logs'
$resultPath = Join-Path $workspace 'results.csv'
$reportPath = Join-Path $workspace 'report.md'

New-Item -Path $downloadPath, $extractPath, $logPath -ItemType Directory -Force | Out-Null

if ($RefreshDownloads) {
    Get-ChildItem -LiteralPath $downloadPath -File -ErrorAction SilentlyContinue | Remove-Item -Force
}

$plumberManifest = Join-Path (Split-Path $PSScriptRoot -Parent) 'Plumber.psd1'
Import-Module $plumberManifest -Force

$modules = Get-GalleryCandidate -Top $CandidateCount |
    Where-Object { -not (Test-VendorModule -Module $_) } |
    Select-Object -First $ModuleCount

if (@($modules).Count -lt $ModuleCount) {
    Write-Warning @(
        "Only selected $(@($modules).Count) modules after filtering " +
        "$CandidateCount Gallery candidates. Increase -CandidateCount."
    )
}

$results = foreach ($module in $modules) {
    Write-Information "Testing $($module.Name) $($module.Version)..." -InformationAction Continue
    $trialSplat = @{
        Module       = $module
        DownloadPath = $downloadPath
        ExtractPath  = $extractPath
        LogPath      = $logPath
        Task         = $Task
    }
    Invoke-ModuleTrial @trialSplat
}

$results | Export-Csv -LiteralPath $resultPath -NoTypeInformation
New-TrialMarkdown -Result $results -Path $reportPath

Write-Information '' -InformationAction Continue
Write-Information "Results: $resultPath" -InformationAction Continue
Write-Information "Report:  $reportPath" -InformationAction Continue
Write-Information "Logs:    $logPath" -InformationAction Continue

$results
