# Structure

## Synopsis

Validates content files are not stored in the root of the module.

## Description

Fails when `.json`, `.yml`, or `.yaml` files are found in the build root.
Content files should live under `Resource`.

## Group

ModuleConventions

## Configuration

None.

## Run

```powershell
Invoke-Plumber -Task Structure
```

## Pass

```text
Resource/config.json
```

## Fail

```text
config.json
```
