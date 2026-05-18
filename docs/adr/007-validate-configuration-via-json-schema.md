# 007: Validate Configuration via JSON Schema

## Status

Proposed — needs more consideration before adoption. The trade-offs
versus a PowerShell-class-based approach were re-examined after empirical
testing of class reload behaviour in PowerShell 7.6.1 (see the
"PowerShell classes" entry in Alternatives Considered). The JSON Schema
direction still looks right for this project, but the error-handling
concession to classes is real and the team is not ready to commit
without more thinky time.

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

ADR 006 (task logic moves into named private functions with thin
orchestration scriptblocks) is independent of this decision and is
recorded separately. The four-line task-scriptblock cap that enforces
ADR 006 also lives in ADR 006, not here — it enforces task *shape*,
which is not the same concern as validating consumer *configuration*.

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

**Null values and defaults.** The current default-merge in
`New-PlumberConfig` produces hashtable values with explicit `$null`
entries for `ModuleManifest`, `DiffBase`, and
`Tasks.PublicFunctionPrefix.Prefix`. `ConvertTo-Json` serialises these
as JSON `null` literals. A schema property declared as `"type":
"string"` rejects `null`, which would cause every default Plumber
config (before the consumer supplies values) to fail validation.

The schema models nullable values as `"type": ["string", "null"]` (or
`"oneOf": [{"type": "string"}, {"type": "null"}]` for richer shapes).
Required-on-use values that nullable-defaults occupy at config-load
time — `ModuleManifest` is the obvious example: every consumer must
supply one for any task to run — are enforced by the consuming code
when it reads the value, not by the schema's `required` keyword. The
schema describes what consumers *may pass*, not what runtime code
*needs*.

The JSON Schema `"default"` keyword is informational, not enforced by
`Test-Json`. Plumber's runtime defaults remain in `New-PlumberConfig`'s
imperative defaults map. Schema `"default"` entries, when present,
exist as documentation hints and potential IDE-tooling input only.
A test should pin that schema `"default"` entries match the imperative
defaults to catch drift between the two sources.

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

## Alternatives Considered

**PowerShell classes for a typed `[PlumberConfig]`.** Honestly the
strongest alternative on error-handling ergonomics. Classes give
free, friendly per-error messages out of PowerShell's property
binder (`"Cannot validate argument on property 'MaxLength'. The 99999
argument is greater than the maximum allowed range of 10000"`), no
custom error-translation code required. They also support richer
validation primitives via `[ValidateScript({...})]`, including
cross-property checks ("if `FileScope='Changed'` then `DiffBase`
required") that are expressible in JSON Schema only through
`dependentRequired` / `if-then-else` constructs.

Classes lose on error aggregation (the property binder stops on the
first invalid value, so consumers fix one error per retry cycle
rather than seeing a composite report) and on direct path attribution
to hashtable keys (PS errors name the type, not the
`Tasks.LineLength.<key>` path consumers typed). These gaps are real
but smaller than the error-handling wins.

The bigger reason to reject is that classes bring permanent concerns
the JSON Schema approach avoids. Tested empirically in PowerShell
7.6.1:

- **Type identity is fragile across module reloads when the class
  definition changes.** If a script holds an instance of
  `[PlumberConfig]` from one Plumber version and then `Import-Module
  Plumber -Force` loads a different definition, the old and new
  `[PlumberConfig]` types coexist in the session. Old-instance method
  calls still dispatch correctly (`$old.GetType()` still reports
  `PlumberConfig`, no "PSObject shells"), but `$old -is
  [PlumberConfig]` and `$old.GetType() -eq $new.GetType()` return
  `False`. Day-to-day this is fine; in self-validation harnesses that
  load Plumber multiple times, this is a footgun that needs care.
- **`using module Plumber` is required for the type literal to be
  visible at all.** `Import-Module Plumber` does not expose module
  class types to the caller's scope (confirmed by test — the literal
  `[PlumberConfig]` throws "Unable to find type" without `using
  module`). `using module` is parsed before the script executes, so
  it creates a parse-time dependency on Plumber being already
  installed and locatable. Not catastrophic; it does add a setup
  step consumers do not need today.
- **Class shapes become part of Plumber's stability contract.**
  Adding, renaming, or removing a property is a breaking change for
  any consumer that constructs the class explicitly via `[Type]@{...}`
  cast. Hashtable keys do not carry the same constraint — adding a
  key is forward-compatible, removing one fails gracefully through
  the validator.

JSON Schema trades some error-message authoring work — bounded
(~100 lines plus golden tests across PS versions and schema-rule
kinds, see Consequences) and addressable — for avoiding all three of
those forever-features. Rejected as the wrong trade for *this*
project, not as the wrong solution in general; with a different
audience or feature set (e.g., a typed runtime config object passed
between subsystems, or rich computed validation), classes might be
the right shape.

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
orchestration scriptblock), done. The schema is the canonical
*validation contract* for the configuration surface.

It is not the single canonical description of configuration. Task
implementations still read values from `$script:PlumberConfig`,
runtime defaults still live imperatively in `New-PlumberConfig`'s
defaults map, and consumer-facing documentation still lives in
per-task `.CONFIGURATION` help blocks (see ADR 004). Adding a setting
touches the schema, the defaults map, the task read sites, and the
help block — four places, not one. The schema makes validation cheap
to author and reliable to enforce; the other three remain authoring
work and benefit from drift-protection tests (see below) rather than
elimination.

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

Friendly error message parsing from `Test-Json` is the implementation
risk in this design. `Test-Json -ErrorVariable` produces error records
whose format and content vary across PowerShell versions and across
schema-rule kinds — `additionalProperties` failures look different from
`enum` failures look different from `minimum`/`maximum` failures. The
"Tasks.LineLength.MaxLenght: unknown property" friendly form requires
parsing the JSON path attribution out of each error record and
synthesising the user-facing message. The parser needs golden tests
against representative failures (typo at top level, typo nested under
Tasks, type mismatch, range violation, enum violation, deeply nested
invalid value, null on non-nullable, multiple errors in one config)
and must fall back to raw `Test-Json` output when path attribution is
missing or unclear. This is more work than a one-line `Test-Json` call
suggests and is the most likely source of "the validator works but the
error message is ugly" follow-up work after the initial implementation.

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
