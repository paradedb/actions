# Lint GitHub Actions

Composite action to validate GitHub Actions workflows with actionlint.

## Usage

```yaml
- name: Lint GitHub Actions
  uses: paradedb/actions/lint-actions@v12
```

No inputs. The action uses the calling repository's actionlint configuration, including `.github/actionlint.yml` when present. Keep repository-specific settings there.
