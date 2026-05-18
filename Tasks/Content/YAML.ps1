<#
    .SYNOPSIS
    Validates YAML files.

    .DESCRIPTION
    Finds `.yml` and `.yaml` files under the build root and verifies that each
    file can be parsed from YAML and serialized back to YAML.

    .GROUP
    Content

    .CONFIGURATION
    None.

    .RUN
    ```powershell
    Invoke-Plumber -Task YAML
    ```

    .PASS
    ```yaml
    name: build
    steps:
      - task: validate
    ```

    .FAIL
    ```yaml
    name: build
    steps:
      - task: validate
        invalid
    ```
#>
Add-BuildTask -Name YAML -Jobs { Invoke-PlumberYAML }
