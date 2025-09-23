function Get-Success {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .EXAMPLE
    #>
    param ()
    $foo = Get-Service | Select-Object -First 1
    return $foo
}