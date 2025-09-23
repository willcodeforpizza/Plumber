<#
    .SYNOPSIS
    Validates the PSD1 metadata is present and correct
#>
task -Name Psd1Data -Jobs {
    $sources = @('Local', 'Github', 'PowershellGallery')
    $publishSource = $script:psd1.PrivateData.PSData.PublishSource
    if ($publishSource -notin $sources) {
        Write-Error "PublishSource is incorrect: $publishSource"
    }
}