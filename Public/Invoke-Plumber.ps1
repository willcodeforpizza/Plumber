function Invoke-Plumber {
    <#
        .SYNOPSIS
        #TODO

        .DESCRIPTION
        #TODO

        .EXAMPLE
        #TODO
    #>
    [CmdletBinding()]
    param ()
    process {
        Invoke-Build -Task Validate -Result buildResult
        $hasError = $buildResult.tasks | Where-Object {$_.Error}
        if($hasError) {
            Write-Error "Build failed!"
        }

        Write-Host "$($buildResult.tasks | Select-Object Name, Error | Format-Table | out-string)"
        Pop-Location
    }
}
