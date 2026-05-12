# PublicFunctionPrefix

## Synopsis

Validates public functions use the configured command prefix.

## Description

Checks files under `Public` and fails when a public function name does not
use the configured noun prefix. The default prefix is the module name.

## Group

ModuleConventions

## Configuration

`PublicFunctionPrefix` overrides the expected prefix. The default is the
configured module name.

`PublicFunctionPrefixExclusions` excludes exact public function names from
this check.

### Example

```powershell
. (Get-PlumberTaskLoader) -Config @{
    PublicFunctionPrefix           = 'My'
    PublicFunctionPrefixExclusions = @('New-Thing')
}
```

## Run

```powershell
Invoke-Plumber -Task PublicFunctionPrefix
```

## Pass

```powershell
function Get-MyThing {}
```

## Fail

```powershell
function Get-Thing {}
```

## Navigation

- [Task index](index.md)
- [Group: ModuleConventions](ModuleConventions.md)
- Previous: [Naming](Naming.md)
- Next: [PublicFunctions](PublicFunctions.md)
