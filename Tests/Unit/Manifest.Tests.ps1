Describe 'Plumber module manifest' {
    BeforeAll {
        $script:manifest = Import-PowerShellDataFile -Path "$PSScriptRoot/../../Plumber.psd1"
    }

    It 'declares PowerShell 7 or newer as the minimum version' {
        $script:manifest.PowerShellVersion | Should -Be '7.0'
    }

    It 'declares support for PowerShell Core only' {
        $script:manifest.CompatiblePSEditions | Should -Be @('Core')
    }
}
