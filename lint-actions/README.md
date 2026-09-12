# Lint GitHub Actions

Composite action to validate GitHub Actions workflows with actionlint 1.7.12. Run after checkout on a Linux x86-64 runner with ShellCheck installed, such as `ubuntu-latest`.

## Usage

```yaml
- name: Lint GitHub Actions
  uses: paradedb/actions/lint-actions@v12
```

No inputs. The action uses the calling repository's actionlint configuration, including `.github/actionlint.yml` when present. Keep custom runner labels and other repository-specific settings there. ShellCheck validates inline shell scripts when available on the runner.
