function Invoke-PlumberNaming {
    <#
        .SYNOPSIS
        Runs the Naming task body.
    #>
    [CmdletBinding()]
    param ()

    $psm1Name = Get-Item (Join-Path $BuildRoot "$script:moduleName.psm1")
    if (-not ($script:psd1.RootModule -ceq $psm1Name.Name)) {
        Write-Error "$($psm1Name.Name) case does not match RootModule"
    }
}
