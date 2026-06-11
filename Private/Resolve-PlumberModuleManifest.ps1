function Resolve-PlumberModuleManifest {
    <#
        .SYNOPSIS
        Resolves the module manifest for a Plumber build root.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string]
        $BuildRoot,

        [string]
        $ModuleManifest
    )

    if ($ModuleManifest) {
        if ([System.IO.Path]::IsPathRooted($ModuleManifest)) {
            return $ModuleManifest
        }

        return Join-Path $BuildRoot $ModuleManifest
    }

    $manifestFiles = @(
        Get-ChildItem $BuildRoot -File -Filter '*.psd1' |
            Sort-Object Name
    )

    if ($manifestFiles.Count -eq 0) {
        throw "No module manifest (*.psd1) was found in '$BuildRoot'. Configure ModuleManifest explicitly."
    }

    if ($manifestFiles.Count -eq 1) {
        return $manifestFiles[0].FullName
    }

    $buildRootName = Split-Path $BuildRoot -Leaf
    $expectedManifestName = "$buildRootName.psd1"
    $matchingManifest = @(
        $manifestFiles |
            Where-Object { $_.Name -eq $expectedManifestName }
    )

    if ($matchingManifest.Count -eq 1) {
        return $matchingManifest[0].FullName
    }

    $manifestNames = $manifestFiles.Name -join ', '
    throw @(
        "ModuleManifest is not configured and manifest discovery is ambiguous in '$BuildRoot'."
        "Expected '$expectedManifestName' or a single *.psd1 file."
        "Found: $manifestNames."
        'Set ModuleManifest in the Plumber config to choose the module manifest explicitly.'
    ) -join ' '
}
