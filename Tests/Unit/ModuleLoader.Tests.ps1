BeforeAll {
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:loaderPath = Join-Path $moduleRoot 'Plumber.psm1'
}

Describe 'Plumber module loader' {
    It 'dot-sources only ps1 files in deterministic path order' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
        $orderPath = Join-Path $tempRoot 'loader-order.txt'

        try {
            New-Item -Path $tempRoot -ItemType Directory | Out-Null
            Copy-Item -Path $script:loaderPath -Destination (Join-Path $tempRoot 'Plumber.psm1')

            foreach ($directory in 'Public', 'Private', 'TaskFunctions') {
                New-Item -Path (Join-Path $tempRoot $directory) -ItemType Directory | Out-Null
            }

            New-Item -Path (Join-Path $tempRoot 'Private/NotAScript.ps1') -ItemType Directory | Out-Null
            Set-Content -Path (Join-Path $tempRoot 'Private/NotAScript.txt') -Value @'
throw 'non-ps1 file loaded'
'@

            $scriptTemplate = 'Add-Content -Path $env:PLUMBER_LOADER_ORDER_PATH -Value ''{0}'''
            Set-Content -Path (Join-Path $tempRoot 'TaskFunctions/Beta.ps1') -Value (
                $scriptTemplate -f 'TaskFunctions/Beta.ps1'
            )
            Set-Content -Path (Join-Path $tempRoot 'Public/Alpha.ps1') -Value (
                $scriptTemplate -f 'Public/Alpha.ps1'
            )
            Set-Content -Path (Join-Path $tempRoot 'Private/Gamma.ps1') -Value (
                $scriptTemplate -f 'Private/Gamma.ps1'
            )

            $env:PLUMBER_LOADER_ORDER_PATH = $orderPath

            Import-Module (Join-Path $tempRoot 'Plumber.psm1') -Force

            Get-Content -Path $orderPath | Should -Be @(
                'Private/Gamma.ps1'
                'Public/Alpha.ps1'
                'TaskFunctions/Beta.ps1'
            )
        }
        finally {
            Remove-Module Plumber -Force -ErrorAction SilentlyContinue
            Remove-Item -Path Env:PLUMBER_LOADER_ORDER_PATH -ErrorAction SilentlyContinue
            if (Test-Path $tempRoot) {
                Remove-Item -Path $tempRoot -Recurse -Force
            }
        }
    }
}
