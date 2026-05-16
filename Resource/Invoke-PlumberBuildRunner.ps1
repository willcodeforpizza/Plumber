param (
    $InvokeBuildCommand,

    [string[]]
    $Task,

    [string]
    $BuildFile,

    [string]
    $ResultVariable,

    [bool]
    $RawOutput
)

$invokeBuildError = $null
try {
    if ($RawOutput) {
        & $InvokeBuildCommand -Task $Task -File $BuildFile -Result $ResultVariable |
            Out-Host
    } else {
        $null = & $InvokeBuildCommand -Task $Task -File $BuildFile -Result $ResultVariable *> $null
    }
} catch {
    $invokeBuildError = $PSItem
}

$invokeBuildResult = Get-Variable -Name $ResultVariable -ValueOnly -ErrorAction SilentlyContinue
Remove-Variable -Name $ResultVariable -ErrorAction SilentlyContinue

if ($invokeBuildResult) {
    $invokeBuildResult
} elseif ($invokeBuildError) {
    throw $invokeBuildError
}
