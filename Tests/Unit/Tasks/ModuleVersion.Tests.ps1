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
}
