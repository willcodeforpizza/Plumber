Add-BuildTask -Name Task1Err -Jobs {
    Write-Error 'This is an error in Task1Err'
}
