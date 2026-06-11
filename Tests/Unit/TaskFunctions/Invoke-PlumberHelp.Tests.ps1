BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberHelp' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'HelpModule'
        $script:publicRoot = Join-Path $script:buildRoot 'Public'
        $script:privateRoot = Join-Path $script:buildRoot 'Private'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -Path $script:publicRoot, $script:privateRoot -ItemType Directory -Force |
            Out-Null
    }

    It 'requires full help for public functions and synopsis-only help for private functions by default' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $script:privateRoot 'Invoke-Helper.ps1') -Value 'function Invoke-Helper {}'

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            Mock Get-PlumberFunctionHelp {
                [pscustomobject]@{
                    Path = $Path
                }
            }
            Mock Test-PlumberFunctionHelp {}

            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberConfig = @{
                Tasks = @{
                    Help = @{
                        PrivateSynopsisOnly = $true
                    }
                }
            }

            Invoke-PlumberHelp

            Should -Invoke Test-PlumberFunctionHelp -ParameterFilter {
                (Split-Path $Help.Path -Leaf) -eq 'Get-Thing.ps1' -and
                    $RequireFullHelp -eq $true
            }
            Should -Invoke Test-PlumberFunctionHelp -ParameterFilter {
                (Split-Path $Help.Path -Leaf) -eq 'Invoke-Helper.ps1' -and
                    $RequireFullHelp -eq $false
            }
        }
    }

    It 'requires full help for non-public functions when configured' {
        Set-Content -Path (Join-Path $script:privateRoot 'Invoke-Helper.ps1') -Value 'function Invoke-Helper {}'

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            Mock Get-PlumberFunctionHelp {
                [pscustomobject]@{
                    Path = $Path
                }
            }
            Mock Test-PlumberFunctionHelp {}

            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberConfig = @{
                Tasks = @{
                    Help = @{
                        PrivateSynopsisOnly = $false
                    }
                }
            }

            Invoke-PlumberHelp

            Should -Invoke Test-PlumberFunctionHelp -ParameterFilter {
                (Split-Path $Help.Path -Leaf) -eq 'Invoke-Helper.ps1' -and
                    $RequireFullHelp -eq $true
            }
        }
    }

    It 'reports help validation failures' {
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'

        InModuleScope Plumber -Parameters @{
            BuildRoot = $script:buildRoot
            PublicRoot = $script:publicRoot
            PrivateRoot = $script:privateRoot
        } {
            Mock Get-PlumberFunctionHelp {
                [pscustomobject]@{
                    Path = $Path
                }
            }
            Mock Test-PlumberFunctionHelp {
                'Get-Thing is missing help'
            }

            $script:moduleFolders = @($PublicRoot, $PrivateRoot)
            $script:PlumberConfig = @{
                Tasks = @{
                    Help = @{
                        PrivateSynopsisOnly = $true
                    }
                }
            }

            { Invoke-PlumberHelp -ErrorAction Stop } |
                Should -Throw -ExpectedMessage '*Get-Thing is missing help*'
        }
    }

    It 'does not treat a differently-cased Public directory as Public on Linux' {
        $caseVariantPublicRoot = Join-Path $script:buildRoot 'public'
        New-Item -Path $caseVariantPublicRoot -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path $script:publicRoot 'Get-Thing.ps1') -Value 'function Get-Thing {}'
        Set-Content -Path (Join-Path $caseVariantPublicRoot 'Invoke-Helper.ps1') -Value 'function Invoke-Helper {}'

        InModuleScope Plumber -Parameters @{
            BuildRoot             = $script:buildRoot
            PublicRoot            = $script:publicRoot
            CaseVariantPublicRoot = $caseVariantPublicRoot
        } {
            Mock Get-PlumberFunctionHelp {
                [pscustomobject]@{
                    Path = $Path
                }
            }
            Mock Test-PlumberFunctionHelp {}

            $script:moduleFolders = @($PublicRoot, $CaseVariantPublicRoot)
            $script:PlumberConfig = @{
                Tasks = @{
                    Help = @{
                        PrivateSynopsisOnly = $true
                    }
                }
            }

            Invoke-PlumberHelp

            Should -Invoke Test-PlumberFunctionHelp -ParameterFilter {
                (Split-Path $Help.Path -Leaf) -eq 'Invoke-Helper.ps1' -and
                    $RequireFullHelp -eq (-not $IsLinux)
            }
        }
    }
}
