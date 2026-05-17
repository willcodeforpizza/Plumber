# 007: Validate Configuration via JSON Schema

## Status

Accepted

## Context

Plumber's configuration model is a permissive hashtable. Consumers pass
`Tasks.<Name> = @{...}` into `Get-PlumberTaskLoader`, and task bodies read
those values directly from `$script:PlumberConfig.Tasks.<Name>`. There is
no validation, so a typo such as `Tasks.LineLenght.MaxLength = 80` silently
flows through, no error fires, and the user discovers the misspelling only
when they notice the rule never reported the expected behavior. Wrong
types (`Minimum = '75'` instead of `75`) and out-of-range values
(`MaxLength = 99999` on a setting that only makes sense up to a few
thousand) are similarly invisible.

The 2026-05-17 external feedback report at `FEEDBACK_REPORT.md` flagged
this explicitly:

> The config merge is permissive. Unknown task keys and setting keys flow
> into the config object. That supports forward-compatible local task
> config, but it also means typos can silently produce surprising behavior.

Real-world rollout of the `PathSeparator` rule to `homelab-pwsh` surfaced
the same pain: when iteratively adjusting `Tasks.PathSeparator.Exclude`
entries, nothing prevented `Exlcude` from being accepted as a brand new
(ignored) key.

A series of design rounds explored five validation shapes:

- PowerShell classes for a typed `[PlumberConfig]`
- Per-task `Test-Plumber<X>Config` sidecar validator functions
- Exported `Invoke-Plumber<X>` functions with central `Get-Command`
  introspection (spiked at v0.0.44, since reverted)
- Inline `& { param() ... } @cfg` per task using PowerShell parameter
  binding
- JSON Schema validation with `Test-Json`

Each had real tradeoffs. The class approach hits PowerShell class reload
semantics that interact badly with self-validation. The sidecar function
approach introduces a Plumber-specific dispatch convention with two files
per task. The exported-function spike worked but inflated Plumber's
public API surface by one command per task and required `.EXAMPLE`,
`SuppressMessageAttribute`, and `Public/` migration boilerplate. The
inline parameter-binding approach is clean but fires validation errors
at task execution start rather than config load, and produces native
PowerShell binding errors rather than friendly path-based messages.

JSON Schema fits the constraints best when used as a one-way validation
gate rather than as the runtime config format. Consumers continue to
author hashtables. Plumber serialises the hashtable to JSON once at
load time, runs it through `Test-Json` against a shipped schema file,
parses any errors into friendly messages, and discards the JSON. The
original hashtable continues unchanged into the task graph. No
serialisation round-trip, no consumer-facing format change, no
PowerShell-class scope quirks, no new dispatch convention.

`Test-Json` is already a Plumber dependency — the `JSONSchema`
validation task uses it. Reusing the same machinery for config
validation does not add a runtime dependency.

ADR 006 establishes that task logic moves into named private functions
with a thin orchestration scriptblock. This decision is independent but
synergistic: a static four-line cap on task scriptblock bodies (enforced
as a unit test, see below) keeps ADR 006's "tasks are thin orchestrators"
principle from drifting back to scriptblock-fat over time.

## Decision

Plumber ships a single JSON Schema file at
`Schemas/plumber-config.schema.json` that describes the full configuration
surface — top-level keys (`ModuleManifest`, `FileScope`, `DiffBase`,
`Tasks`) and every per-task settings block (`Tasks.LineLength.MaxLength`,
`Tasks.PathSeparator.Exclude`, and so on). The schema uses
`additionalProperties: false` at every level so unknown keys are rejected.

At config-load time, a new `Test-PlumberConfig` private function (called
from `TaskLoader.ps1` after the defaults merge) performs a one-way
validation pass:

1. Convert the merged hashtable to JSON via `ConvertTo-Json -Depth 100`.
2. Validate against the shipped schema via
   `Test-Json -Json $json -SchemaFile $schemaPath -ErrorAction
   SilentlyContinue -ErrorVariable errors`.
3. If validation fails, parse each error into a friendly message naming
   the offending path (`Tasks.LineLength.MaxLenght: unknown property` rather
   than the raw `Test-Json` output) and throw a single composite error.
4. Discard the JSON. The original hashtable continues unchanged.

Schema example (abbreviated):

```json
{
    "$schema": "https://json-schema.org/draft-07/schema#",
    "type": "object",
    "additionalProperties": false,
    "properties": {
        "ModuleManifest": { "type": "string" },
        "FileScope":      { "enum": ["All", "Changed"] },
        "DiffBase":       { "type": "string" },
        "Tasks": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
                "LineLength": {
                    "type": "object",
                    "additionalProperties": false,
                    "properties": {
                        "MaxLength": {
                            "type": "integer",
                            "minimum": 1,
                            "maximum": 10000
                        },
                        "Exclude": {
                            "type": "array",
                            "items": { "type": "string" }
                        }
                    }
                }
            }
        }
    }
}
```

**Local task handling.** Plumber.Tasks.Local entries are dynamically
folded into the schema at validation time. `Test-PlumberConfig` reads
`Tasks.Local` (the consumer's list of local task files), derives the
task name from each filename (`MyLocal.ps1` → `MyLocal`), and adds each
to a copy of the schema's `Tasks.properties` as
`{ "type": "object", "additionalProperties": true }`. The task name is
then a recognised key, but its config body is unchecked. This preserves
typo protection on built-in task names while leaving local task config
permissive. Local task authors who want stricter validation can ship a
sidecar `.schema.json` later; that extension point is not built now.

**Plumber.Release and future plugins.** Each shipping loader owns its
own schema and runs its own `Test-Json` pass. Plumber's shipped schema
covers built-in task config only. This matches the existing pattern
where `Plumber.Release.Tasks.<Name>` is validated by `Plumber.Release`,
not by Plumber.

**Task-body four-line cap (enforces ADR 006).** A new unit test at
`Tests/Unit/TaskBodyLength.Tests.ps1` parses every
`Tasks/<Group>/<Name>.ps1` via AST, locates each `Add-BuildTask` call,
extracts its `-Jobs` scriptblock argument(s), and fails if any
scriptblock body contains more than four lines of code (excluding
comments and blank lines). Four is a deliberate generosity: it allows a
quick guard clause plus a call to the private function (`if (-not
$x) { return }` plus `Invoke-Plumber<Name>` plus closing brace plus
whitespace), but is too small to host meaningful business logic.

This test lives in ADR 007 rather than ADR 006 because ADR 006 describes
the *principle* (thin task scriptblocks delegating to named functions),
and ADR 007 introduces the *validation infrastructure* that keeps the
codebase honest about that principle over time. The four-line cap is a
Plumber self-check; it does not run as part of the consumer-facing
`Validate` pipeline.

## Alternatives Considered

**PowerShell classes for a typed `[PlumberConfig]`.** Provides
type-checked property access and `using module` IntelliSense in build
files, but PowerShell classes do not survive `Import-Module -Force`
cleanly — old instances become `PSObject` shells. This interacts badly
with Plumber's self-validation story. Consumers would also need
`using module Plumber` at the top of every build file, creating a
parse-time dependency on Plumber being installed before the file is
read. Rejected.

**Two-way JSON configuration (`plumber.config.json` as the authoring
format).** Same machinery as the chosen design but extended to let
consumers author config in JSON files. Provides IDE autocomplete via
`$schema` references but forces JSON authoring on a PowerShell-native
audience, splits config across two files (build script + JSON), and
loses access to dynamic config (env-var lookups, computed excludes).
Rejected for the current audience. The schema introduced by this ADR
can be referenced by a `plumber.config.json` mode later without
rework if Plumber goes public and the consumer mix shifts.

**Inline `& { param() ... } @cfg` per task using PowerShell parameter
binding.** Uses PowerShell's own binding machinery as the validator;
zero new files. But validation fires at task execution start rather
than config load (so a single config-typo run produces one task
failure at a time rather than a composite report), and native PS
binding errors are not as friendly as parsed schema errors. Also
incompatible with ADR 006's "task scriptblocks are thin orchestrators"
because the validation `param()` block would have to live inside the
scriptblock. Rejected.

**Per-task `Test-Plumber<X>Config` sidecar validator functions.** Each
task ships a sibling validator whose param block is the schema, with a
central orchestrator that dispatches by naming convention. Cleaner than
JSON Schema for an in-PowerShell audience but introduces a
Plumber-specific dispatch convention and a second file per task.
Rejected — the JSON Schema option puts validation rules in one
declarative file rather than scattering them across N validator
functions.

**Exported `Invoke-Plumber<X>` functions with central
`Test-PlumberConfig` introspection (the spike at v0.0.44).** Each task
body becomes a named function in `Public/`. The validator walks
`Get-Command` on those functions to validate config at load time. Gives
`Get-Help` and standalone task invocation for free. But Plumber's own
`PublicFunctions` rule forces moving the functions to `Public/`, which
forces `.EXAMPLE` blocks and `FunctionsToExport` entries; the existing
"`$script:PlumberConfig.Tasks.<Name>.Exclude` is read by
`Get-PlumberTaskFile` internally" pattern forces
`SuppressMessageAttribute` workarounds; full rollout adds ~20 commands
to the public API. The validation benefits do not justify the public
API surface explosion for an internal-consumer beta tool. Rejected.

**Do nothing.** Status quo. The external feedback report and PathSeparator
rollout pain establish this as a real ergonomic gap. Rejected.

## Consequences

Plumber gains one new file (`Schemas/plumber-config.schema.json`) and
one new private helper (`Private/Test-PlumberConfig.ps1`) that runs a
`Test-Json` pass and parses errors into friendly form. `TaskLoader.ps1`
gains a single call to `Test-PlumberConfig` after the defaults merge.

Adding a new task config becomes: declare the per-task properties block
in the schema, write the task per ADR 006 (private function + thin
orchestration scriptblock), done. The schema is the single canonical
description of the configuration surface. There is no second place to
remember to update when a task gains a new setting.

Configuration errors surface at config-load time with friendly path-based
messages. Multiple errors compose into a single failure report rather
than one-at-a-time discovery across multiple runs.

The JSON serialisation is one-way and discarded. Plumber does not
consume the JSON form internally; tasks continue to read from
`$script:PlumberConfig.Tasks.<Name>` as a hashtable. No
PSCustomObject coercion, no numeric precision loss, no nested-hashtable
identity surprises.

Local task config bodies remain permissive (only the task name is
validated against the dynamic composition). Local task authors who
want strict validation can ship a sidecar schema as a future opt-in
extension; that mechanism is not built in this round.

Plumber.Release and any future plugin loaders own their own validation;
Plumber's schema does not need to know about them. This matches the
existing per-loader ownership pattern.

The task-body four-line cap unit test prevents drift from ADR 006's
"thin orchestration scriptblocks" principle. New tasks added in the
wrong shape fail Plumber's own `PesterUnit` task before merge. The cap
is deliberately generous (four lines accommodates a guard clause plus
the function call) but small enough to make business logic obvious by
its absence.

The shipped schema doubles as documentation. Doc generation can render
it as a config reference page in addition to (or alongside) the
existing per-task `.CONFIGURATION` help blocks. ADR 004's custom task
help schema and this configuration schema describe the same surface in
two formats; a future test could pin that the documented
`.CONFIGURATION` keys match the schema's `Tasks.<Name>.properties`
keys to catch drift between the two.

This ADR closes the configuration validation question that has been
explored across multiple design rounds. Future work focuses on rollout
(extending the schema as each task migrates to ADR 006 shape) and on
the optional `plumber.config.json` mode if it ever becomes useful.
