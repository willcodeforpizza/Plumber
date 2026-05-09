<#
    .SYNOPSIS
    Validates content files are not stored in the root of the module
#>
Add-BuildTask -Name Structure -Jobs {
    $misplacedContent = Get-ChildItem $BuildRoot -File |
        Where-Object {$_.Extension -in '.json', '.yml', '.yaml'}

    if ($misplacedContent) {
        $fileList = $misplacedContent.Name -join ', '
        Write-Error "Content files should be in Resource folder: $fileList"
    }
}
