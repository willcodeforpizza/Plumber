# 001: Record Architecture Decisions

## Status

Accepted

## Context

Plumber is accumulating decisions about task organization, configuration, documentation, and validation behavior. These decisions affect how contributors extend the module and how consuming projects use it.

Commit history records what changed, but it does not reliably explain why a direction was chosen.

## Decision

Plumber will record architecture decisions as Markdown files in `docs/adr`.

ADR files will use three-digit numbering and a short descriptive name, for example `001-record-architecture-decisions.md`.

Each ADR should be concise and use this structure:

- `Status`
- `Context`
- `Decision`
- `Consequences`

ADRs may include an `Alternatives Considered` section when rejected options are likely to be useful context later.

Accepted ADRs should not be rewritten to change the decision. If a decision changes, a later ADR should supersede the earlier one.

## Consequences

Important design choices have a stable place to live outside issue threads and commit messages.

Contributors can understand current behavior by reading a small set of decision records.

The ADRs must be maintained as the module design changes.
