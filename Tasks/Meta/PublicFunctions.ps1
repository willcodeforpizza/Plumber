task PublicFunctions {
    Get-ChildItem "$BuildRoot\Public" | ForEach-Object {
        if ($_.BaseName -notin $script:psd1.FunctionsToExport){
            Write-Error "$($_.BaseName) is not in $($script:psd1.FunctionsToExport)"
        }
    }
}
