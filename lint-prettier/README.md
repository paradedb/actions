# Lint Prettier

Composite action to check YAML or Markdown formatting with Prettier, with optional markdownlint checks.

## Usage

```yaml
- name: Lint Markdown
  uses: paradedb/actions/lint-prettier@v12
  with:
    patterns: "{**/*.md,**/*.mdx}"
    markdown: "true"
```

Inputs:

- `patterns`: Newline-separated Prettier file patterns (default `**/*.{yml,yaml}`).
- `markdown`: Also lint `**/*.md` with markdownlint (default `false`).
- `prettier-source`: `shared` (default) or `pnpm`.
- `ignore-path`: Optional explicit Prettier ignore file; empty uses Prettier defaults.

Prettier 3.9.6 and markdownlint-cli 0.49.1 are pinned directly in the install step. Configuration files such as `.prettierrc`, `.prettierignore`, and `.markdownlint.yaml` belong to each calling repository. Markdown lint ignores `node_modules` at every depth.

For a pnpm repository, set `prettier-source: pnpm` to use its own Prettier and plugins. The repository's `packageManager` field selects pnpm, and its frozen lockfile is installed with scripts disabled. Update shared linter versions in `action.yml` and keep local pre-commit versions aligned.
