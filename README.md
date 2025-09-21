# Plumber

A wrapper around Invoke-Build for PowerShell Pipelines.
Plumber offers a series of validation tests intended to be run locally during development

## To run

- Install the module
- Browse to the module to test
- Copy / commit `.\Plumber\Resource\ModuleName.build.ps1` to the root of your module
- Rename `ModuleName.build.ps1` to the name of your module
- Run `Invoke-Plumber`
