# 006: Move Task Logic to Private Functions

## Status

Accepted

## Context

Every Plumber task today is registered as an `Add-BuildTask -Name <Name> -Jobs
{ <body> }` call where the body contains the full task logic — file
discovery, content parsing, AST walks, failure formatting, error throwing,
and so on. Some bodies are a handful of lines; several are 30 to 80 lines.

This pattern was inherited from how Invoke-Build naturally registers tasks.
It mixes two concerns that grow at different rates and want different review
attention:

- **Orchestration**: what is this task called, which group does it belong to,
  what does it depend on (`?Task` optional dependencies, the `SetVariables`
  prelude, parent-group composition).
- **Execution**: what does the task actually compute, how does it format
  errors, what helpers does it call, what configuration does it read.

When orchestration and execution share an anonymous scriptblock, several
problems compound as the module grows:

- The logic is not testable in isolation. `Invoke-Pester` cannot target a
  scriptblock that is locked inside Invoke-Build's `${*}` task registry.
  Tests have to invoke the full task graph via `Invoke-PlumberBuild` or
  `Invoke-Plumber`, which is slow, hides failures behind task framing, and
  makes assertion-level debugging awkward.
- The scope and reload boilerplate cleaned up in v0.0.34 was partly a symptom
  of this design. The more logic the scriptblock contained, the more
  defensive helper reloading appeared. Cargo-cult guards accumulated where
  named functions would have made scope obvious.
- The body has no name and no `Get-Command`/`Get-Help` surface area, so a
  reader who wants to find what runs when `LineLength` validates has to
  open the task file and scroll the scriptblock. There is no symbol to
  jump to.
- Reuse across tasks requires extracting helpers to `Private/` anyway,
  partially defeating the in-line model and creating a split-brain pattern
  where some logic lives in the scriptblock and some lives in `Private/`.

The 2026-05-17 spike at branch `spike-config-validation-introspection` (now
discarded) confirmed empirically that extracting a task body into a named
private function is straightforward, takes no significant refactor effort
per task, and produces dramatically more readable tasks. The spike pursued
a different goal (configuration validation via parameter binding) but the
ergonomic side-effect of moving `LineLength`'s body into a named function
was striking enough to be worth a decision in its own right.

This ADR records the architectural decision to consistently separate
orchestration from execution across all built-in Plumber tasks. The
configuration validation question — how the framework catches typos and
type errors — is a separate concern addressed in ADR 007.

## Decision

Plumber will store each built-in task's logic in a named function at
`TaskFunctions/Invoke-Plumber<TaskName>.ps1`, a new folder dedicated to
holding task bodies. The task file at
`Tasks/<Group>/<TaskName>.ps1` retains only:

- The existing comment-based help block (`.SYNOPSIS`, `.GROUP`,
  `.CONFIGURATION`, `.RUN`, `.PASS`, `.FAIL`, etc., as ADR 004 defines).
- A thin `Add-BuildTask` registration that calls the private function.

For example, after the change `Tasks/CodeQuality/LineLength.ps1` becomes:

```powershell
<#
    .SYNOPSIS
    Validates PowerShell source files do not exceed the configured line length.
    .GROUP
    CodeQuality
    .CONFIGURATION
    `Tasks.LineLength.MaxLength` controls the maximum line length. Default 115.
    `Tasks.LineLength.Exclude` excludes matching files from this task.
    ...
#>
Add-BuildTask -Name LineLength -Jobs SetVariables, { Invoke-PlumberLineLength }
```

And `TaskFunctions/Invoke-PlumberLineLength.ps1` holds the body:

```powershell
function Invoke-PlumberLineLength {
    [CmdletBinding()]
    param ()

    $cfg = $script:PlumberConfig.Tasks.LineLength
    $extensions = '.ps1', '.psm1', '.psd1'
    $files = Get-PlumberTaskFile -Task LineLength -Extension $extensions

    $failures = foreach ($file in $files) {
        $lineNumber = 0
        foreach ($line in Get-Content $file.FullName) {
            $lineNumber++
            if ($line.Length -gt $cfg.MaxLength) {
                "$($file.Name):$lineNumber - Line is $($line.Length) characters >$($cfg.MaxLength)"
            }
        }
    }
    if ($failures) { Write-Error ($failures -join (', ' + [Environment]::NewLine)) }
}
```

The private function takes no parameters and reads configuration directly
from `$script:PlumberConfig.Tasks.<Name>`, matching today's pattern. (How
that configuration is validated is the subject of ADR 007.)

Functions are kept module-internal rather than exported. Plumber's own
`PublicFunctions` rule treats exported functions as a curated API surface;
adding ~20 new `Invoke-Plumber<X>` exports to expose internal task bodies
would inflate the public surface without any consumer-facing benefit, and
each export would require an `.EXAMPLE` block per the `Help` rule and a
matching `Public/<Name>.ps1` file path. None of that buys consumers
anything they could not get by invoking the task via
`Invoke-Plumber -Task <Name>`.

`TaskFunctions/` is a new folder. TaskLoader.ps1 and Plumber.psm1 each
gain one additional `foreach` loop that dot-sources `TaskFunctions/*.ps1`
alongside the existing `Private/*.ps1` discovery (~6 lines of framework
change total). Both folders end up in build-file scope (see v0.0.34's
`Tests/Integration/HelperScope.Tests.ps1`), so `Invoke-Plumber<TaskName>`
is reachable from the task scriptblock without any further wiring.
Plumber's own `PublicFunctions` rule needs to recognise `TaskFunctions/`
as a known non-public folder so it does not flag the functions as
"exported but not in `Public/`."

Migration is per-task and incremental. Each task migrates independently
without coordination; the framework treats migrated and unmigrated tasks
identically because both end up calling code from the same scope. The
four-line task-scriptblock cap described below makes the migration
finished-state both verifiable and durable.

### Enforcement — four-line cap and task/body pairing

Two related unit tests enforce the shape this ADR establishes:

`Tests/Unit/TaskBodyLength.Tests.ps1` parses every
`Tasks/<Group>/<Name>.ps1` via AST, locates each `Add-BuildTask` call,
extracts its `-Jobs` scriptblock argument(s), and fails if any
scriptblock body contains more than four lines of code (excluding
comments and blank lines). Four is deliberately generous: it allows a
quick guard clause plus a call to the task-body function (`if (-not $x)
{ return }` plus `Invoke-Plumber<Name>` plus closing brace plus
whitespace), but is too small to host meaningful business logic.

`Tests/Unit/TaskFunctionPairing.Tests.ps1` parses every
`Add-BuildTask -Name X` registration and asserts that
`TaskFunctions/Invoke-PlumberX.ps1` exists and defines
`Invoke-PlumberX`. Catches the case where a task scriptblock is added
without its task-body function (or vice versa) — the four-line cap
does not catch this on its own because a one-line scriptblock that
calls a nonexistent function passes the cap.

Both checks live in this ADR (not in ADR 007) because they enforce
task *shape*, not configuration. They are Plumber self-checks; they
do not run as part of the consumer-facing `Validate` pipeline. New
tasks added in the wrong shape fail Plumber's own `PesterUnit` task
before merge.

## Alternatives Considered

**Keep the current scriptblock-only pattern.** This avoids any migration
work but produces logic that is not testable in isolation, has no symbol
table presence, and continues mixing orchestration with execution as the
project grows. Rejected — the cost of inaction compounds as task count
grows, and the spike showed migration is cheap per task.

**Move task bodies to public functions exported via `FunctionsToExport`.**
The exported-function spike pursued this shape. It works but inflates the
public API surface by ~20 commands with no consumer benefit, requires
`.EXAMPLE` blocks per task to satisfy Plumber's own `Help` rule, requires
`Public/<Name>.ps1` files per Plumber's own `PublicFunctions` rule, and
exposes implementation details that consumers should not depend on (a task
body's signature is not a stability contract). Rejected in favour of
keeping the functions module-internal — the symbol-table and testability
wins are the same either way.

**Place task-body functions in `Private/` rather than a new
`TaskFunctions/` folder.** The simpler option: reuse the existing
`Private/` folder that TaskLoader already dot-sources, zero framework
change. But `Private/` today contains a cohesive set of ~20 framework
helpers (`Get-PlumberTaskFile`, `Copy-PlumberHashtable`,
`Test-PlumberTaskEnabled`, etc.) that are reused across the codebase.
Adding ~20 task-body functions doubles the folder size and mixes two
distinct categories of code: "reusable framework utility" and "the body
of one specific task." Browsing `Private/` stops being informative;
readers cannot quickly tell which files are utilities vs which contain
task logic. A dedicated `TaskFunctions/` folder costs ~6 lines of
framework change (TaskLoader + Plumber.psm1 dot-source) plus a
small awareness in Plumber's own `PublicFunctions` rule, in exchange
for a cleaner four-way split: `Public/` (exported API), `Private/`
(framework helpers), `TaskFunctions/` (task bodies), `Tasks/` (task
registration). Rejected the shared-`Private/` placement in favour of
the dedicated folder.

**Use PowerShell classes with task methods.** A `[PlumberTask]` base class
with a virtual `Invoke()` method, subclassed per task. Cleaner type
hierarchy in principle, but PowerShell class reload semantics interact
badly with self-validation (see ADR 005 and the v0.0.34 work), and the
class machinery does not add value over named functions for a non-OO
codebase. Rejected.

**Refactor opportunistically, leave existing tasks untouched until they
need editing.** This avoids upfront work but leaves Plumber in a permanent
mixed state where some tasks follow the new pattern and some do not.
Readers would have to learn both shapes and remember which tasks are on
which side. Rejected in favour of a consistent migration across all
built-in tasks, paired with the four-line cap test to keep new tasks
honest.

## Consequences

Plumber gains a new `TaskFunctions/` folder containing ~20 files, one
per built-in task. Each existing `Tasks/<Group>/<Name>.ps1` shrinks to
a help block plus a one-line `Add-BuildTask` call. Net line count is
roughly flat; the distribution changes from "few large files" to
"more small files" and gains explicit separation between task
orchestration (in `Tasks/`) and task execution (in `TaskFunctions/`).
TaskLoader.ps1 and Plumber.psm1 each gain a small `foreach` loop to
dot-source the new folder. Plumber's own `PublicFunctions` rule gains
awareness of `TaskFunctions/` as a recognised non-public folder.

Plumber's own tests can target task bodies more directly. A new spec at
`Tests/Unit/TaskFunctions/Invoke-PlumberLineLength.Tests.ps1` sets up a fixture
`$script:PlumberConfig` value (and `$BuildRoot`, and any file-discovery
caches the task reads through) and calls the function without going
through the full Invoke-Build harness. This is faster and produces
cleaner test failures than today's integration-shaped tests, but it is
not "pure" isolated unit testing in the dependency-injection sense — the
functions still read script-scope state. A future cleanup may move
tasks that benefit from real isolation onto parameters that take config
and paths explicitly, where doing so does not make the call site uglier.

Adding ~20 new `Invoke-Plumber<TaskName>` functions under `TaskFunctions/`
expands the set of symbols dot-sourced into the consumer's build-file
scope by TaskLoader. These are not exported via the module's
`FunctionsToExport`, but they are reachable by name from inside any
consumer's `*.build.ps1`. The trade-off versus the exported-function
alternative is: fewer public commands shown by `Get-Command -Module
Plumber`, but more dot-sourced implementation symbols visible in
build-file scope. This is an accepted trade-off — neither shape is
"free" — chosen because it does not pollute the consumer's global
command table and does not create stability expectations against
function signatures.

Consumers see no change. Task names, group names, exclusions, the loader
configuration shape, and `Invoke-Plumber -Task <Name>` all behave
identically. The migration is internal to Plumber.

Future task authoring becomes simpler: write a private function with the
real logic, register a one-line `Add-BuildTask` that calls it, add the
help block. The four-line cap described in the Decision section makes
the discipline self-enforcing.

Local tasks (consumer-supplied `Tasks.Local`) are out of scope for this
decision. Local task authors choose their own shape; Plumber does not
require local tasks to follow the private-function pattern, though they
benefit from doing so for the same reasons.

Plumber.Release is also out of scope. Its tasks are owned by a separate
module and will be migrated separately when convenient. The decision here
applies to Plumber's own built-in tasks only.
