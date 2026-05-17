Describe 'ModuleVersion task' {
    It 'errors when PSGallery source cannot find the module' {
        function Add-BuildTask {
            param (
                [string]
                $Name,

                [object[]]
                $Jobs
            )

            $script:taskName = $Name
            $script:taskJobs = $Jobs
        }

        function Write-Build {
            param ($Color, $Message)

            $null = $Color
            $null = $Message
        }

        . "$PSScriptRoot/../../../Tasks/ReleaseHygiene/ModuleVersion.ps1"
        Mock Find-Module {}

        $script:PlumberConfig = @{
            ModuleRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
            Tasks      = @{
                ModuleVersion = @{
                    Source = 'PSGallery'
                }
            }
        }
        $script:moduleName = 'MissingModule'
        $script:psd1 = @{
            ModuleVersion = '1.0.0'
        }

        $script:taskName | Should -Be 'ModuleVersion'
        $job = $script:taskJobs[-1]

        {
            $ErrorActionPreference = 'Stop'
            & $job
        } | Should -Throw -ExpectedMessage '*MissingModule is not published to PSGallery*'
    }

    It 'passes when 3-segment manifest is greater than 4-segment PSGallery version' {
        # Regression: with raw [version] cast, [version]'0.0.36' has Revision=-1
        # and [version]'0.0.35.0' has Revision=0, so equal-Build but unequal-
        # Revision was being compared. For Major/Minor/Build equal cases the
        # 3-segment psd1 string could appear "less than" the 4-segment gallery
        # string. Normalising both through ConvertTo-PlumberSemVer fixes it.
        function Add-BuildTask {
            param ([string] $Name, [object[]] $Jobs)
            $script:taskName = $Name
            $script:taskJobs = $Jobs
        }
        function Write-Build {
            param ($Color, $Message)
            $null = $Color
            $null = $Message
        }

        . "$PSScriptRoot/../../../Private/ConvertTo-PlumberSemVer.ps1"
        . "$PSScriptRoot/../../../Tasks/ReleaseHygiene/ModuleVersion.ps1"
        Mock Find-Module {
            [pscustomobject]@{
                Name    = 'BumpedVersionModule'
                Version = [version]'0.0.35.0'
            }
        }

        $script:PlumberConfig = @{
            ModuleRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
            Tasks      = @{ ModuleVersion = @{ Source = 'PSGallery' } }
        }
        $script:moduleName = 'BumpedVersionModule'
        $script:psd1 = @{ ModuleVersion = '0.0.36' }

        $job = $script:taskJobs[-1]
        {
            $ErrorActionPreference = 'Stop'
            & $job
        } | Should -Not -Throw
    }
}
