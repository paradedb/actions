# ParadeDB Actions

Shared GitHub Actions building blocks for ParadeDB repositories.

## Components

- [apt-install](apt-install/) -- Composite action to install APT packages with retry.
- [slack-alert](slack-alert/) -- Composite action for Slack failure alerts.
- [upstream-sync](upstream-sync/) -- Reusable workflows for keeping a target repository rebased on an upstream repository.

## Lint and check actions

Keep workflow triggers, concurrency, permissions, runners, job names, and checkout
in the calling repository. These composite actions run against that checkout on
Linux. Configuration files and repository-specific build or validation commands
remain in the caller.

| Action                 | Purpose                                                             | Inputs                                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lint-prettier`        | YAML formatting, or Markdown lint and formatting                    | `patterns` (newline-separated, defaults to `**/*.{yml,yaml}`), `markdown` (`false`), `prettier-source` (`shared` or `pnpm`), `ignore-path` (optional) |
| `lint-format`          | CRLF, trailing whitespace, final newlines, optional JSON validation | `exclude` (newline-separated Git exclusion pathspecs without the `:(exclude)` prefix), `check-json` (`false`)                                         |
| `lint-bash`            | Formatting, shebangs, strict mode, ShellCheck                       | `formatter` (`beautysh` or `shfmt`), `allow-sh` (`false`), `strict-mode-exclude` (newline-separated exact paths), `source-path` (`scripts`)           |
| `check-typo`           | Pinned codespell with filename checking                             | `config`, `ignore-words-file`, `skip` (comma-separated codespell patterns)                                                                            |
| `lint-pr-title`        | Conventional PR titles                                              | `github-token` (required, `pull-requests: read`)                                                                                                      |
| `lint-docker`          | Hadolint                                                            | `directory` (`docker`), `exclude` (`docker/Dockerfile.template`), `config` (`.hadolint.yaml`)                                                         |
| `lint-actions`         | Pinned actionlint, including inline shell checks                    | None; Linux x86-64 runner required                                                                                                                    |
| `setup-terraform-lint` | Shared Terraform and TFLint tool versions                           | None; run repository-specific checks in subsequent steps                                                                                              |

Example steps after checkout:

```yaml
- name: Lint Markdown
  uses: paradedb/actions/lint-prettier@v12
  with:
    patterns: "{**/*.md,**/*.mdx}"
    markdown: "true"
```

Use published release tags for shared actions, matching the existing components.
These lint and check actions are introduced in `v12`. Merge the shared-action PR
and publish `v12` before merging consumer PRs. Future shared changes use the same
repository-wide release tags; consumers update their action version as needed.

Prettier 3.9.6 and markdownlint-cli 0.49.1 are pinned directly in the action's
install step. No package manifest or lockfile is needed for the shared linters.
The caller's Prettier and markdownlint configuration is used. Set
`prettier-source: pnpm` to install the caller's frozen lockfile with scripts
disabled and run its own Prettier (including plugins). Its `packageManager` field
selects pnpm. Markdown lint always ignores `node_modules` at any depth.

To update shared Node linters, change their exact versions in the install step in
`lint-prettier/action.yml` and run the lint checks. Keep local pre-commit versions aligned with these versions. Python linters
are installed in isolated environments: codespell 2.4.3, Beautysh 6.4.3, and
ShellCheck 0.11.0.1. The optional shfmt formatter uses 3.13.1.

File-format checks inspect tracked files and preserve Git pathspec semantics.
Exclusions only affect whitespace and final newlines; CRLF and optional JSON
validation cover all tracked files. Bash checks inspect tracked `*.sh` files,
including hidden directories, and handle spaces and shell metacharacters in paths.
Formatting retains the existing `**/*.sh` glob scope and skips hidden paths;
shebang, strict-mode, and ShellCheck checks still cover tracked hidden scripts.
The strict-mode annotation `# @paradedb-skip-check-pipefail` is supported.

Spelling configuration stays in each repository. Empty spelling inputs do not
override settings in `.codespellrc`, `setup.cfg`, or `pyproject.toml`. The Python
codespell CLI replaces the former Docker wrapper, so Docker Hub credentials are
no longer needed by this check.

## License

MIT
