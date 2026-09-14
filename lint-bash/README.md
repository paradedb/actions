# Lint Bash

Composite action to check tracked shell scripts for formatting, shebangs, strict mode, and ShellCheck errors.

## Usage

```yaml
- name: Lint Bash
  uses: paradedb/actions/lint-bash@v12
  with:
    source-path: scripts
```

Inputs:

- `source-path`: ShellCheck source search path (default `scripts`).
