# Plumber

## 0.0.33
- Added: `FunctionFiles` task for one function per PowerShell function file

## 0.0.32
- Changed: Plumber installs missing internal task dependencies when the module loads
- Added: `Install-PlumberDependency` for opt-in repository build dependencies
- Documented: Plumber dependency behavior for local development and CI
- Added: ADR for separating runtime dependencies from build dependencies

## 0.0.31
- Changed: `Invoke-Plumber` preserves and returns Invoke-Build task context even when tasks fail
- Changed: Summary output prints full failure details without table truncation
- Changed: Plumber validation uses `Invoke-Plumber` as the public entry point

## 0.0.30
- Fixed: `Validate` exits non-zero after optional validation task failures are collected
- Fixed: `Invoke-Plumber` parses Invoke-Build result objects for CI pass/fail status

## 0.0.29
- Changed: Plumber config now nests task-owned settings under `Tasks`
- Changed: Path exclusions now use `Tasks.<Task>.Exclude`
- Changed: Task graph exclusions and local tasks now use `Tasks.Exclude` and `Tasks.Local`

## 0.0.28
- Changed: ModuleVersion fails when PSGallery source cannot find the module
- Changed: Release automation now uses Plumber.Release
- Changed: Pester dependency now uses version 5.7.1

## 0.0.27
- Added: ModuleVersion can validate against semantic git tags from a configured remote
- Changed: ModuleVersion ignores prerelease git tags by default

## 0.0.26
- Changed: Document PowerShell Gallery installation in the README

## 0.0.25
- Added: Invoke-Plumber GitHub Actions workflow and CI output mode
- Changed: Module dependencies are listed in the module manifest ModuleList

## 0.0.24
- Added: PublicFunctionPrefix task for validating public command noun prefixes

## 0.0.23
- Changed: Expanded PublicFunctions to validate public file, export, and private function boundaries

## 0.0.22
- Changed: Split TaskLoader internals into focused private helper functions

## 0.0.21
- Changed: PesterUnit and PesterIntegration run Pester in isolated PowerShell jobs
- Fixed: Self-validation when another Plumber module version is already loaded

## 0.0.20
- Added: FileScope Changed reports the selected changed file count
- Changed: Clarified changed-file validation examples

## 0.0.19
- Added: FileScope config for changed-file validation
- Added: DiffBase config for pull request changed-file validation

## 0.0.18
- Fixed: PSScriptAnalyzer test-folder filtering for similarly named directories
- Added: PSScriptAnalyzer shared file discovery coverage

## 0.0.17
- Added: Plumber local validation for task help comments
- Fixed: Invoke-Plumber accepts local task names

## 0.0.16
- Added: LocalTasks config for project-specific validation tasks under the Local group
- Added: Local task documentation

## 0.0.15
- Added: BuildModule task for creating a publishable module folder
- Added: PublishModule task for publishing the staged module folder
- Added: PublishRelease task for creating GitHub tags and releases

## 0.0.14
- Added: BuildFile parameter for Invoke-Plumber
- Added: MIT license and gallery license metadata
- Changed: JSON validation now scans JSON files across the build root
- Changed: JSONSchema path mappings now match repository-relative JSON paths
- Changed: Invoke-Plumber now resolves the build file from the current directory by default
- Changed: ToDo now only reports TODO comment markers
- Removed: Structure task

## 0.0.13
- Added: ExcludePaths config for task-scoped file exclusions
- Changed: File-based validation tasks now use shared Plumber file discovery
- Changed: Backticks now ignores escaped backticks and Markdown code fences

## 0.0.12
- Added: Invoke-Plumber output modes for summary, table, JSON and raw output
- Changed: Invoke-Plumber now defaults to concise summary output
- Changed: Failed Invoke-Plumber validation now throws after writing output

## 0.0.11
- Added: Config examples for task exclusion, coverage and line length
- Changed: ExcludeTasks now supports excluding parent task groups

## 0.0.10
- Added: LineLength task for configurable maximum line length validation

## 0.0.9
- Added: Backticks task for PowerShell line-continuation style validation

## 0.0.8
- Added: Help task for public and private function comment-based help validation
- Added: PrivateHelpSynopsisOnly config for private function help validation
- Changed: Document Help task configuration

## 0.0.7
- Added: JSONSchema task using Test-Json and JsonSchemas config
- Changed: Document JSON schema configuration

## 0.0.6
- Added: Configurable task loading through Get-PlumberTaskLoader and Tasks/TaskLoader.ps1
- Added: PlumberConfig support for ModuleManifest, CoverageMinimum, IncludeTestsInPssa and ExcludeTasks
- Changed: Plumber's build file loads tasks through the configurable loader
- Changed: PesterUnit, PesterIntegration and CodeCoverage load directly under CodeQuality

## 0.0.5
- Removed: Meta and Psd1Data tasks
- Added: Validation parent task groups: CodeQuality, ReleaseHygiene, Content and ModuleConventions
- Added: Manifest and YAML tasks
- Added: Unit tests for Invoke-Plumber task selection, build failures and wrapper execution
- Changed: Aligned JSON, Structure, Pester and PSScriptAnalyzer tasks with the standalone build pipeline
- Changed: Replaced Invoke-Build calls in Invoke-Plumber with a private Invoke-PlumberBuild wrapper
- Changed: Fixed self-validation on Linux when Plumber runs its own Pester and coverage tasks

## 0.0.4
- Added: Linux support
- Changed: Fixed module import in psm1

## 0.0.3
- Changed: Added named params on tasks, general formatting

## 0.0.2
- Added: Synopsis to each task, task dependencies & example modules

## 0.0.1
- Added: `Invoke-Plumber`
- Added: Module init
