# Plumber

A wrapper around Invoke-Build for PowerShell Pipelines.
Plumber offers a series of validation tests intended to be run locally during development

## To run

- Install the module
- Browse to the module to test
- Copy / commit `.\Plumber\Resource\ModuleName.build.ps1` to the root of your module
- Rename `ModuleName.build.ps1` to the name of your module
- Run `Invoke-Plumber`

## Example successful output

<details>
<summary>Successful pipeline output</summary>

```
Invoke-Plumber

Build Validate C:\gh\Plumber\Tests\Assets\PassingModule\PassingModule.build.ps1
Redefined task 'CodeCoverage'.
Task /Validate/SetVariables
BuildRoot: C:\gh\Plumber\Tests\Assets\PassingModule
moduleName: PassingModule
moduleFolders: C:\gh\Plumber\Tests\Assets\PassingModule\Public C:\gh\Plumber\Tests\Assets\PassingModule\Private
Done /Validate/SetVariables 00:00:00.0034282
Done /Validate/?ModuleVersion/SetVariables
Task /Validate/?ModuleVersion
Done /Validate/?ModuleVersion 00:00:00.0013559
Task /Validate/?Changelog
Done /Validate/?Changelog 00:00:00.0020862
Task /Validate/?JSON
Done /Validate/?JSON 00:00:00.0040841
Done /Validate/?Meta/SetVariables
Task /Validate/?Meta/?PublicFunctions
Done /Validate/?Meta/?PublicFunctions 00:00:00.0022782
Task /Validate/?Meta/?Structure
Done /Validate/?Meta/?Structure 00:00:00.0021429
Done /Validate/?Meta/?Naming/SetVariables
Task /Validate/?Meta/?Naming
Done /Validate/?Meta/?Naming 00:00:00.0018159
Task /Validate/?Meta/?Psd1Data
Done /Validate/?Meta/?Psd1Data 00:00:00.0010085
Task /Validate/?Meta/?ToDo
Done /Validate/?Meta/?ToDo 00:00:00.0123327
Done /Validate/?Meta 00:00:00.0215329
Done /Validate/?PSScriptAnalyzer/SetVariables
Task /Validate/?PSScriptAnalyzer
Done /Validate/?PSScriptAnalyzer 00:00:00.0113804
Done /Validate/?Pester/?PesterUnit/SetVariables
Task /Validate/?Pester/?PesterUnit

Starting discovery in 1 files.
Discovery found 0 tests in 26ms.
Starting code coverage.
Running tests.
Tests completed in 25ms
Tests Passed: 0, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
Processing code coverage result.
Covered 0% / 75%. 3 analyzed Commands in 1 File.
Done /Validate/?Pester/?PesterUnit 00:00:00.0879512
Task /Validate/?Pester/?CodeCoverage
Done /Validate/?Pester/?CodeCoverage 00:00:00.0113862
Done /Validate/?Pester/?PesterIntegration/SetVariables
Task /Validate/?Pester/?PesterIntegration

Starting discovery in 1 files.
Discovery found 1 tests in 24ms.
Running tests.
[+] C:\gh\Plumber\Tests\Assets\PassingModule\Tests\Integration\Get-Success.Integration.Tests.ps1 58ms (1ms|34ms)
Tests completed in 60ms
Tests Passed: 1, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
Done /Validate/?Pester/?PesterIntegration 00:00:00.1032045
Done /Validate/?Pester 00:00:00.2041396
Done /Validate 00:00:00.2516111
Build succeeded. 16 tasks, 0 errors, 0 warnings 00:00:00.3480225

Name              Error
----              -----
SetVariables
ModuleVersion
Changelog
JSON
PublicFunctions
Structure
Naming
Psd1Data
ToDo
Meta
PSScriptAnalyzer
PesterUnit
CodeCoverage
PesterIntegration
Pester
Validate
```
</details>

## Example failing output

<details>
<summary>Failing pipeline output</summary>

```
Invoke-Plumber

Build Validate C:\gh\Plumber\Tests\Assets\FailingModule\FailingModule.build.ps1
Task /Validate/SetVariables
BuildRoot: C:\gh\Plumber\Tests\Assets\FailingModule
moduleName: FailingModule
moduleFolders: C:\gh\Plumber\Tests\Assets\FailingModule\Public C:\gh\Plumber\Tests\Assets\FailingModule\Private
Done /Validate/SetVariables 00:00:00.0031803
Done /Validate/?ModuleVersion/SetVariables
Task /Validate/?ModuleVersion
ERROR: PSD1 version might be out of date. PSD1 version 0.0.1 Published version 1.0.0
At C:\gh\Plumber\Tasks\ModuleVersion.ps1:5 char:1
+ task -Name ModuleVersion -Jobs SetVariables, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Task /Validate/?Changelog
ERROR: Changelog might be out of date. PSD1 version 0.0.1 changelog version 0.0.0
At C:\gh\Plumber\Tasks\Changelog.ps1:5 char:1
+ task -Name Changelog -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Task /Validate/?JSON
ERROR: The JSON is not valid with the schema: Required properties ["Value"] are not present at '/2'
At C:\gh\Plumber\Tasks\JSON.ps1:15 char:19
+         if (-not (Test-Json -Path $jsonFile -Schema $schema)) {
+                   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
At C:\gh\Plumber\Tasks\JSON.ps1:5 char:1
+ task -Name JSON -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Meta/SetVariables
Task /Validate/?Meta/?PublicFunctions
ERROR: Get-Failure is not in FunctionsToExport
At C:\gh\Plumber\Tasks\Meta\PublicFunctions.ps1:5 char:1
+ task -Name PublicFunctions -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Task /Validate/?Meta/?Structure
ERROR: JSON files should be in Resource folder
At C:\gh\Plumber\Tasks\Meta\Structure.ps1:5 char:1
+ task -Name Structure -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Meta/?Naming/SetVariables
Task /Validate/?Meta/?Naming
ERROR: FailingModule.psm1 case does not match RootModule
At C:\gh\Plumber\Tasks\Meta\Naming.ps1:5 char:1
+ task -Name Naming -Jobs SetVariables, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Task /Validate/?Meta/?Psd1Data
ERROR: PublishSource is incorrect:
At C:\gh\Plumber\Tasks\Meta\Psd1Data.ps1:5 char:1
+ task -Name Psd1Data -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
Task /Validate/?Meta/?ToDo
ERROR: Get-Failure.ps1: Write function
At C:\gh\Plumber\Tasks\Meta\ToDo.ps1:5 char:1
+ task -Name ToDo -Jobs {
+ ~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Meta 00:00:00.0316933
Done /Validate/?PSScriptAnalyzer/SetVariables
Task /Validate/?PSScriptAnalyzer
ERROR: Get-Failure.ps1:12 - PSUseDeclaredVarsMoreThanAssignments - The variable 'foo' is assigned but never used.
At C:\gh\Plumber\Tasks\PSScriptAnalyzer.ps1:5 char:1
+ task -Name PSScriptAnalyzer -Jobs SetVariables, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Pester/?PesterUnit/SetVariables
Task /Validate/?Pester/?PesterUnit

Starting discovery in 1 files.
Discovery found 1 tests in 23ms.
Starting code coverage.
Running tests.
[-] Get-Failure.Does a thing.Does not work 3ms (2ms|1ms)
 Expected $true, but got $false.
 at $false | Should -Be $true, C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Unit\Get-Failure.Tests.ps1:10
 at <ScriptBlock>, C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Unit\Get-Failure.Tests.ps1:10
Tests completed in 67ms
Tests Passed: 0, Failed: 1, Skipped: 0, Inconclusive: 0, NotRun: 0
Processing code coverage result.
Covered 0% / 75%. 1 analyzed Command in 1 File.
ERROR: Pester failed with 1 error(s)
At C:\gh\Plumber\Tasks\Pester\PesterUnit.ps1:5 char:1
+ task -Name PesterUnit -Jobs SetVariables, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Pester/?CodeCoverage/?PesterUnit
Task /Validate/?Pester/?CodeCoverage
ERROR: 0% coverage for C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Unit\Get-Failure.Tests.ps1
At C:\gh\Plumber\Tasks\Pester\CodeCoverage.ps1:5 char:1
+ task -Name CodeCoverage -Jobs ?PesterUnit, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Pester/?PesterIntegration/SetVariables
Task /Validate/?Pester/?PesterIntegration

Starting discovery in 1 files.
Discovery found 1 tests in 24ms.
Running tests.
[-] Get-Failure.Integrates a thing.Does not work 2ms (1ms|0ms)
 Expected $true, but got $false.
 at $false | Should -Be $true, C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Integration\Get-Failure.Integration.Tests.ps1:10
 at <ScriptBlock>, C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Integration\Get-Failure.Integration.Tests.ps1:10
Tests completed in 63ms
Tests Passed: 0, Failed: 1, Skipped: 0, Inconclusive: 0, NotRun: 0
ERROR: Pester failed with 1 error(s)
At C:\gh\Plumber\Tasks\Pester\PesterIntegration.ps1:5 char:1
+ task -Name PesterIntegration -Jobs SetVariables, {
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Done /Validate/?Pester 00:00:00.2331845
Done /Validate 00:00:00.3016122
Build completed with errors. 16 tasks, 12 errors, 0 warnings 00:00:00.3764525
Invoke-Plumber: Build failed!

Name              Error
----              -----
SetVariables
ModuleVersion     PSD1 version might be out of date. PSD1 version 0.0.1 Published version 1.0.0
Changelog         Changelog might be out of date. PSD1 version 0.0.1 changelog version 0.0.0
JSON              The JSON is not valid with the schema: Required properties ["Value"] are not present at '/2'
PublicFunctions   Get-Failure is not in FunctionsToExport
Structure         JSON files should be in Resource folder
Naming            FailingModule.psm1 case does not match RootModule
Psd1Data          PublishSource is incorrect:
ToDo              Get-Failure.ps1: Write function
Meta
PSScriptAnalyzer  Get-Failure.ps1:12 - PSUseDeclaredVarsMoreThanAssignments - The variable 'foo' is assigned bu…
PesterUnit        Pester failed with 1 error(s)
CodeCoverage      0% coverage for C:\gh\Plumber\Tests\Assets\FailingModule\Tests\Unit\Get-Failure.Tests.ps1
PesterIntegration Pester failed with 1 error(s)
Pester
Validate
```
</details>
