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
        uses: paradedb/actions/lint-pr-title@v12
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

Inputs:

- `github-token`: Required token with `pull-requests: read` permission.

Include `edited` in the calling workflow's pull request event types so title changes rerun the check.
