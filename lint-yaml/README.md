# Lint YAML

Composite action to check YAML formatting with Prettier.

## Usage

```yaml
- name: Lint YAML
  uses: paradedb/actions/lint-yaml@v12
```

Inputs:

- `ignore-path`: Optional explicit Prettier ignore file; empty uses Prettier defaults.

Each repository owns its Prettier configuration and ignore files, such as `.prettierrc` and `.prettierignore`.
