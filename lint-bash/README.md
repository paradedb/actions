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

The action checks tracked `*.sh` files, including hidden scripts. Accepted shebangs are `#!/bin/bash`, `#!/usr/bin/env bash`, and `#!/bin/sh`. Formatting uses shfmt with two-space indentation and indented case branches. Strict mode requires `set -eu` for sh scripts and `set -euo pipefail` (or `set -Eeuo pipefail`) for Bash scripts. Scripts may opt out of strict-mode checks with `# @paradedb-skip-check-pipefail`.
