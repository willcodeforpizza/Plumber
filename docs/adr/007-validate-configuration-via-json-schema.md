# 007: Validate Configuration via Internal Spec Rules

## Status

Proposed.

## Context

Plumber's configuration model is a permissive hashtable. Consumers pass
`Tasks.<Name> = @{...}` into `Get-PlumberTaskLoader`, and task bodies read
those values directly from `$script:PlumberConfig.Tasks.<Name>`. Without
validation, a typo such as `Tasks.LineLenght.MaxLength = 80` is accepted as
an inert config key, so users discover mistakes only when expected checks do
not behave differently.

Wrong types (`Minimum = '75'` instead of `75`) and out-of-range values
(`MaxLength = 99999` on a setting that only makes sense up to a few
thousand) are similarly invisible. Real-world rollout of the
`PathSeparator` rule surfaced the same pain: misspelled task settings were
accepted as brand new ignored keys.

A series of design rounds explored several validation shapes:

- PowerShell classes for a typed `[PlumberConfig]`
- Per-task `Test-Plumber<X>Config` sidecar validator functions
- Exported `Invoke-Plumber<X>` functions with central `Get-Command`
  introspection
- Inline `& { param() ... } @cfg` per task using PowerShell parameter
  binding
- JSON Schema validation with `Test-Json`
- An internal dotted-path rule map

JSON Schema initially looked attractive because `Test-Json` is already used
by Plumber's JSONSchema task and the schema could double as external
tooling input. The implementation spike showed that stable, friendly error
messages would still require custom PowerShell parsing of `Test-Json`
errors across schema rules and PowerShell versions. The schema would reject
bad config reliably, but aggregation, path attribution, and "did you mean"
suggestions would be custom code layered on top.

## Decision

Plumber validates merged configuration with an internal dotted-path rule map
returned by `Get-PlumberConfigRule`. `Test-PlumberConfig` runs at task
loader time after `New-PlumberConfig` merges defaults and user config.

The rule map describes the built-in config surface:

- top-level keys such as `ModuleManifest`, `FileScope`, `DiffBase`,
  `IncludeModuleFolders`, and runtime-injected `BuildRoot`
- task-level arrays such as `Tasks.Local`
- per-task settings such as `Tasks.<Task>.RunWhen`,
  `Tasks.LineLength.MaxLength` and `Tasks.JSONSchema.Schemas`

`Invoke-PlumberConfigValidator` implements the primitive validators:
`string`, `string-array`, `integer`, `boolean`, `enum`, and structured
`object-array` items. Invalid config is collected into one composite error
with dotted paths. Unknown keys use `Get-PlumberConfigSuggestion` so common
typos can report a nearby valid key.

Configured local tasks remain permissive. `Test-PlumberConfig` derives
allowed local task names from `Tasks.Local`, accepts matching
`Tasks.<LocalTaskName>` blocks, and does not inspect their bodies. This
keeps typo protection for built-in tasks while preserving local task
extensibility.

## Consequences

Plumber owns the validation messages directly instead of translating
`Test-Json` output. That makes aggregation, strict type checks, nullable
values, local task exceptions, and suggestions straightforward to test.

The tradeoff is that Plumber now has a small custom validation DSL. Adding
a new built-in setting means updating the runtime defaults, task
implementation, documentation, and `Get-PlumberConfigRule`. Drift tests pin
that every default config leaf has a validation rule and that validation
rules match known config leaves or runtime-only keys.

The current primitive set intentionally stays small. If Plumber later needs
many cross-property checks, richer item shapes, generated config docs, or
external tooling support, JSON Schema or a typed config object should be
reconsidered.

## Alternatives Considered

**JSON Schema via `Test-Json`.** Reliable for shape validation and useful
for external tooling, but friendly error messages require parsing
PowerShell error records whose text and structure vary by schema rule and
PowerShell version. Rejected for this implementation because the internal
rule map gives the required user experience with less moving machinery.

**PowerShell classes.** Strong for typed properties and native validation
attributes, but binder errors are first-failure oriented, class reload
semantics complicate module self-validation, and class shapes become part of
Plumber's long-term compatibility contract. Rejected for now.

**Per-task validator functions.** Keeps validation in PowerShell and near
task ownership, but introduces a second file and naming convention for each
task. Rejected in favor of one central config contract.

**Exported task functions with central introspection.** Gives standalone
task invocation and `Get-Help` benefits, but inflates the public API surface
by one command per task and adds boilerplate that does not pay for the
validation need. Rejected.

**Do nothing.** Leaves typo and type mistakes silent. Rejected.
