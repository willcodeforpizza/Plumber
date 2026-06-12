function Invoke-PlumberGit {
    <#
        .SYNOPSIS
        Runs git with the supplied arguments and returns stdout lines only.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string[]]
        $ArgumentList
    )

    $stdout = [System.Collections.Generic.List[string]]::new()
    $stderr = [System.Collections.Generic.List[string]]::new()
    & git @ArgumentList 2>&1 | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $stderr.Add([string]$_)
        } else {
            $stdout.Add([string]$_)
        }
    }

    if ($LASTEXITCODE -ne 0) {
        $detail = (@($stderr) + @($stdout)) -join ' '
        throw "git $($ArgumentList -join ' ') failed. $detail"
    }

    foreach ($line in $stderr) {
        Write-Verbose "git: $line"
    }

    $stdout.ToArray()
}
