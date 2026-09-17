# Lint PR Title

Composite action to validate conventional pull request titles.

## Usage

```yaml
permissions:
  pull-requests: read

jobs:
  lint-pr-title:
    runs-on: ubuntu-latest
    steps:
      - name: Validate PR Title
        uses: paradedb/actions/lint-pr-title@v13
```

Include `edited` in the calling workflow's pull request event types so title changes rerun the check.
