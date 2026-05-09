function Invoke-PlumberBuild {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Task,

        [Parameter(Mandatory)]
        [string]
        $BuildFile
    )

    $invokeBuild = Get-Command Invoke-Build
    $resultVariable = "plumberBuildResult_$([guid]::NewGuid().ToString('N'))"
    $null = & $invokeBuild -Task $Task -File $BuildFile -Result $resultVariable
    Get-Variable -Name $resultVariable -ValueOnly
    Remove-Variable -Name $resultVariable -ErrorAction SilentlyContinue
}
