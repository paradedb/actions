# Lint Format

Composite action to check tracked files for CRLF endings, trailing whitespace, and missing final newlines, with optional JSON validation.

## Usage

```yaml
- name: Lint File Format
  uses: paradedb/actions/lint-format@v13
  with:
    exclude: |
      *.sql
      *.out
    check-json: "true"
```

Inputs:

- `exclude`: Newline-separated Git exclusion pathspecs, without the `:(exclude)` prefix.
- `check-json`: Validate all tracked JSON files (default `false`).

Each repository supplies its own exclusions. Exclusions apply only to whitespace and final-newline checks; CRLF and optional JSON validation cover all tracked files. Binary files are omitted from whitespace and final-newline checks.
