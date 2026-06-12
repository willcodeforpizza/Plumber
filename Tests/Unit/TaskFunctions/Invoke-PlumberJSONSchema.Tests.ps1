BeforeAll {
    if (-not (Get-Module Plumber)) {
        Import-Module "$PSScriptRoot/../../../Plumber.psd1" -Force
    }
}

Describe 'Invoke-PlumberJSONSchema' {
    BeforeEach {
        $script:buildRoot = Join-Path $TestDrive 'SchemaModule'
        Remove-Item -Path $script:buildRoot -Recurse -Force -ErrorAction SilentlyContinue
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

    It 'reports every schema-invalid file instead of aborting on the first' {
        Set-Content -Path (Join-Path $script:resourceRoot 'bad-one.json') -Value '{"name":1}'
        Set-Content -Path (Join-Path $script:resourceRoot 'bad-two.json') -Value '{"other":true}'

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

            Invoke-PlumberJSONSchema -ErrorAction SilentlyContinue -ErrorVariable schemaErrors

            # ErrorVariable also collects Test-Json's own caught records;
            # assert on the task's reported failures only.
            $failures = @(
                $schemaErrors |
                    Where-Object {$_.ToString() -like 'JSON schema validation failed:*'}
            )
            $failures.Count | Should -Be 2
            $failures[0].ToString() | Should -BeLike '*bad-one.json*'
            $failures[1].ToString() | Should -BeLike '*bad-two.json*'
        }
    }

    It 'includes the failure reason in the error message' {
        Set-Content -Path (Join-Path $script:resourceRoot 'broken.json') -Value '{"name":'

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

            Invoke-PlumberJSONSchema -ErrorAction SilentlyContinue -ErrorVariable schemaErrors

            $failures = @(
                $schemaErrors |
                    Where-Object {$_.ToString() -like 'JSON schema validation failed:*'}
            )
            $failures.Count | Should -Be 1
            $failures[0].ToString() | Should -BeLike '*broken.json - *'
        }
    }
}
