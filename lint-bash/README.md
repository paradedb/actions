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

- `allow-sh`: Allow `#!/bin/sh` alongside Bash shebangs (default `false`).
- `strict-mode-exclude`: Newline-separated exact paths exempt from strict-mode checks.
- `source-path`: ShellCheck source search path (default `scripts`).

The action checks tracked `*.sh` files, including hidden scripts. Formatting uses shfmt with two-space indentation and indented case branches. Scripts may opt out of strict-mode checks with `# @paradedb-skip-check-pipefail`.
