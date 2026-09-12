# Check Typo

Composite action to check spelling and filenames with codespell 2.4.3.

## Usage

```yaml
- name: Check Typo
  uses: paradedb/actions/check-typo@v12
  with:
    ignore-words-file: .codespellignore
    skip: Cargo.lock,./tests
```

Inputs:

- `config`: Optional codespell configuration file, such as `.codespellrc`.
- `ignore-words-file`: Optional file of ignored words.
- `skip`: Optional comma-separated codespell exclusion patterns.

Each repository owns its spelling configuration and `.codespellignore`. Empty inputs preserve the repository's codespell defaults and configuration.
