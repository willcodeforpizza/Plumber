# 004: Document Tasks With a Custom Schema

## Status

Accepted

## Context

Plumber exposes validation behavior through Invoke-Build tasks. These tasks are not exported PowerShell commands, but users still need task-level documentation that explains what each task checks, how to run it, how it is grouped, and what passing and failing examples look like.

PowerShell help tooling is designed around commands and parameters. Plumber task documentation needs task-specific concepts such as parent groups, included tasks, configuration keys, run examples, pass examples, and fail examples.

The documentation should be easy to keep close to the task implementation while still producing Markdown pages that render well on GitHub.

## Decision

Plumber will document Invoke-Build tasks using comment blocks adjacent to task definitions.

Task documentation will use a Plumber-specific schema with these sections:

- `.SYNOPSIS`
- `.DESCRIPTION`
- `.GROUP`
- `.INCLUDES`
- `.CONFIGURATION`
- `.RUN`
- `.PASS`
- `.FAIL`

`.RUN` applies to every documented task and shows how to run that task explicitly.

`.PASS` and `.FAIL` apply to leaf validation tasks and show concise examples of behavior that should pass or fail the task. Group tasks should not use `.PASS` or `.FAIL`; they should document the tasks they include.

Generated Markdown files will be written under `docs/tasks` and linked from a generated task table in `README.md`.

Documentation generation is a build/documentation concern. A `GenerateDocs` task may create task documentation, but it should not be part of Plumber's validation pipeline.

## Alternatives Considered

Plumber could use PlatyPS for task pages, but PlatyPS is designed for PowerShell command help and does not naturally model Invoke-Build tasks or task-specific sections such as group, includes, pass, and fail.

Plumber could store task documentation in a separate metadata file, but that would separate the docs from the task definitions and increase the chance that task behavior and documentation drift apart.

Plumber could hand-write task pages without generation, but that would make it harder to keep the README task table and individual task pages consistent.

## Consequences

Task documentation lives close to the task behavior it describes.

Plumber needs custom tooling to parse task documentation blocks and generate Markdown.

The generated Markdown can use GitHub-rendered fenced code blocks for `.RUN`, `.PASS`, and `.FAIL` examples.

Task documentation validation is specific to the Plumber repository and should not become a core Plumber validation task for all consuming modules.
