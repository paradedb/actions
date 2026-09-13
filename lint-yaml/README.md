# Lint YAML

Composite action to check YAML formatting with Prettier.

## Usage

```yaml
- name: Lint YAML
  uses: paradedb/actions/lint-yaml@v12
```

Inputs:

- `prettier-source`: `shared` (default) or `pnpm`.
- `ignore-path`: Optional explicit Prettier ignore file; empty uses Prettier defaults.

Each repository owns its Prettier configuration and ignore files, such as `.prettierrc` and `.prettierignore`. Linter versions are pinned directly in the install step.

For a pnpm repository, set `prettier-source: pnpm` to use its own Prettier and plugins. The repository's `packageManager` field selects pnpm, and its frozen lockfile is installed with scripts disabled.
