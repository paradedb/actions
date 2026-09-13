# Lint Markdown

Composite action to lint Markdown with markdownlint and format Markdown and MDX with Prettier.

## Usage

```yaml
- name: Lint Markdown
  uses: paradedb/actions/lint-markdown@v12
```

Inputs:

- `prettier-source`: `shared` (default) or `pnpm`.
- `ignore-path`: Optional explicit Prettier ignore file; empty uses Prettier defaults.

Markdown lint ignores `node_modules` at every depth. Each repository owns its `.markdownlint.yaml`, Prettier configuration, and ignore files. Linter versions are pinned directly in the install step.

For a pnpm repository, set `prettier-source: pnpm` to use its own Prettier and plugins. The repository's `packageManager` field selects pnpm, and its frozen lockfile is installed with scripts disabled.
