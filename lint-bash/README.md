# Lint Bash

Composite action to check tracked shell scripts for formatting, shebangs, strict mode, and ShellCheck errors. Run after checkout on Linux.

## Usage

```yaml
- name: Lint Bash
  uses: paradedb/actions/lint-bash@v12
  with:
    source-path: scripts
```

Inputs:

- `formatter`: `beautysh` (default) or `shfmt`.
- `allow-sh`: Allow `#!/bin/sh` alongside Bash shebangs (default `false`).
- `strict-mode-exclude`: Newline-separated exact paths exempt from strict-mode checks.
- `source-path`: ShellCheck source search path (default `scripts`).

The action checks tracked `*.sh` files. Formatting skips hidden paths, matching the existing `**/*.sh` glob behavior; shebang, strict-mode, and ShellCheck checks include hidden scripts. Scripts may opt out of strict-mode checks with `# @paradedb-skip-check-pipefail`.

Tool versions are pinned in the action: Beautysh 6.4.3, shellcheck-py 0.11.0.1, and optional shfmt 3.13.1. Keep repository pre-commit settings aligned with the chosen formatter.
