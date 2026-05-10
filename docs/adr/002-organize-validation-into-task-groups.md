# 002: Organize Validation Into Task Groups

## Status

Accepted

## Context

Plumber provides Invoke-Build tasks for validating PowerShell modules. A single flat task list is difficult to scan and makes it harder to run a meaningful subset of validation.

The validation work naturally falls into a few areas:

- code correctness and quality
- release readiness
- repository content
- PowerShell module conventions

Consumers need a default validation entry point, but they also need the ability to run narrower checks during development.

## Decision

Plumber will organize core validation tasks into four parent groups:

- `CodeQuality`
- `ReleaseHygiene`
- `Content`
- `ModuleConventions`

The `Validate` task will remain the default entry point and will run the core validation groups.

Leaf tasks should live under the group that best describes the reason for the check, not necessarily the implementation mechanism used by the check.

## Consequences

The task graph is easier to understand from both the command line and documentation.

Users can run focused subsets such as `Invoke-Plumber -Task CodeQuality` without remembering every leaf task.

Adding a new core validation task requires deciding which group owns it.

Some tasks could reasonably belong to more than one group. In those cases, Plumber should prefer the group that best matches the user-facing purpose of the validation.
