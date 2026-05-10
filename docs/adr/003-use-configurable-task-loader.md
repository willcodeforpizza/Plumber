# 003: Use a Configurable Task Loader

## Status

Accepted

## Context

Plumber needs a stable core validation pipeline while still allowing consuming projects to adjust validation behavior. Examples include excluding tasks, changing thresholds and selecting files.

Hard-coding all behavior in `Plumber.build.ps1` would make the module simpler internally but would force consumers to fork or wrap Plumber for common project differences.

## Decision

Plumber will load validation tasks through a task loader and a `PlumberConfig` object.

The loader is responsible for assembling the task graph from Plumber's core tasks and configuration. Configuration is responsible for project-specific behavior such as task exclusion, coverage thresholds, line length limits, manifest selection, and other supported validation settings.

The loader should discover configuration through the consuming module's build context rather than requiring consumers to edit Plumber module files.

The configuration surface should stay explicit. Plumber should add named config keys for supported behavior instead of relying on callers to mutate internal task implementation details.

## Alternatives Considered

Consuming projects could edit or fork `Plumber.build.ps1`, but that would make upgrades harder and would move project-specific behavior into Plumber's implementation.

Plumber could expose broad script hooks, but that would make the validation pipeline harder to reason about and test.

Plumber could read configuration from environment variables, but that would make validation behavior less visible in the repository and harder to reproduce from source alone.

## Consequences

Consuming projects can adjust validation without editing Plumber's task files. The individual project configuration lives with the build.ps1 file of the module being tested, not in Plumber.

Plumber can still have opinionated defaults, but there should be options to change this on a per module basis.

The loader becomes part of Plumber's architecture and needs unit coverage. New configuration keys need documentation and tests because they affect the public behavior of the validation pipeline.
