$script:moduleRoot = $PSScriptRoot

# Load the full public/private/task function surface. Dependency installation is
# explicit; command entry points validate/import their dependencies when needed.
Get-ChildItem (
    Join-Path $PSScriptRoot 'Public'
), (
    Join-Path $PSScriptRoot 'Private'
), (
    Join-Path $PSScriptRoot 'TaskFunctions'
) -File -Filter '*.ps1' |
    Sort-Object FullName |
        ForEach-Object { . $_.FullName }
