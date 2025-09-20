task Psd1Data {
    $sources = @("Local", "Github", "PowershellGallery")
    $publishSource = $script:psd1.PrivateData.PSData.PublishSource
    if ($publishSource -notin $sources) {
        Write-Error "PublishSource is incorrect: $publishSource"
    }
}
