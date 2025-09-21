function Get-Success {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
    #>
    param ()
    $foo = GEt-Service | Select-Object -First 1
    return $foo
}