# YAML

## Synopsis

Validates YAML files.

## Description

Finds `.yml` and `.yaml` files under the build root and verifies that each
file can be parsed from YAML and serialized back to YAML.

## Group

Content

## Configuration

None.

## Run

```powershell
Invoke-Plumber -Task YAML
```

## Pass

```yaml
name: build
steps:
  - task: validate
```

## Fail

```yaml
name: build
steps:
  - task: validate
    invalid
```
