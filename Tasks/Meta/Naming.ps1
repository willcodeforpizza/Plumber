<#
    .SYNOPSIS
    Validates the name of the psm1 in the RootModule, matches the file name on disk
#>
task -Name Naming -Jobs SetVariables, {
    $psm1Name = Get-Item "$BuildRoot\$script:moduleName.psm1"
    if (-not ($script:psd1.RootModule -ceq $psm1Name.Name)) {
        Write-Error "$($psm1Name.Name) case does not match RootModule"
    }
}
