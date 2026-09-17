# Lint Markdown

Composite action to lint Markdown with markdownlint and format Markdown and MDX with Prettier.

## Usage

```yaml
- name: Lint Markdown
  uses: paradedb/actions/lint-markdown@v13
```

Inputs:

- `ignore-path`: Optional explicit Prettier ignore file; empty uses Prettier defaults.

Markdown lint ignores `node_modules` at every depth. Each repository owns its `.markdownlint.yaml`, Prettier configuration, and ignore files.
