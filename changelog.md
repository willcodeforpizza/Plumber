# Plumber

## 0.0.5
- Add validation parent task groups: CodeQuality, ReleaseHygiene, Content and ModuleConventions
- Add Manifest and YAML tasks
- Remove Meta and Psd1Data tasks
- Align JSON, Structure, Pester and PSScriptAnalyzer tasks with the standalone build pipeline
- Replace Invoke-Build calls in Invoke-Plumber with a private Invoke-PlumberBuild wrapper
- Add unit tests for Invoke-Plumber task selection, build failures and wrapper execution
- Fix self-validation on Linux when Plumber runs its own Pester and coverage tasks

## 0.0.4
- Fix module import in psm1
- Support Linux

## 0.0.3
- Changed: Added named params on tasks, general formatting

## 0.0.2
- Added: Synopsis to each task, task dependencies & example modules

## 0.0.1
- Added: `Invoke-Plumber`
- Module init
