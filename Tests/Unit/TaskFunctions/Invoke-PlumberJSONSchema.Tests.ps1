BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberJSONSchema' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'SchemaModule'
        $script:resourceRoot = Join-Path $script:buildRoot 'Resource'
        $script:schemaRoot = Join-Path $script:resourceRoot 'Schema'
        New-Item -Path $script:schemaRoot -ItemType Directory -Force | Out-Null

        Set-Content -Path (Join-Path $script:resourceRoot 'config.json') -Value '{"name":"plumber"}'
        Set-Content -Path (Join-Path $script:schemaRoot 'config.schema.json') -Value @'
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": ["name"],
    "properties": {
        "name": {
            "type": "string"
        }
    }
}
'@
    }

    It 'validates configured JSON schema mappings' {
        InModuleScope Plumber -Parameters @{BuildRoot = $script:buildRoot} {
            function Write-Build {
                param ($Color, $Message)

                $null = $Color
                $null = $Message
            }

            $script:PlumberFiles = $null
            $script:PlumberChangedFiles = $null
            $script:PlumberChangedFilesLoaded = $false
            $script:PlumberConfig = @{
                BuildRoot = $BuildRoot
                FileScope = 'All'
                Tasks     = @{
                    JSONSchema = @{
                        Exclude = @('Resource/Schema/*.json')
                        Schemas = @(
                            @{
                                Path   = 'Resource/**/*.json'
                                Schema = 'Resource/Schema/config.schema.json'
                            }
                        )
                    }
                }
            }

            { Invoke-PlumberJSONSchema -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
