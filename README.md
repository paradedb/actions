# ParadeDB Actions

Shared GitHub Actions building blocks for ParadeDB repositories.

## Components

- [apt-install](apt-install/) -- Composite action to install APT packages with retry.
- [check-typo](check-typo/) -- Composite action to check spelling with codespell.
- [lint-actions](lint-actions/) -- Composite action to lint GitHub Actions workflows with actionlint.
- [lint-bash](lint-bash/) -- Composite action to format and lint Bash scripts.
- [lint-docker](lint-docker/) -- Composite action to lint Dockerfiles with Hadolint.
- [lint-format](lint-format/) -- Composite action to check file endings, whitespace, and JSON validity.
- [lint-markdown](lint-markdown/) -- Composite action to lint Markdown with markdownlint and Prettier.
- [lint-pr-title](lint-pr-title/) -- Composite action to validate pull request titles.
- [lint-yaml](lint-yaml/) -- Composite action to lint YAML with Prettier.
- [slack-alert](slack-alert/) -- Composite action for Slack failure alerts.
- [upstream-sync-rebase](upstream-sync-rebase/) -- Composite action to rebase target patches onto upstream.
- [upstream-sync-promote](upstream-sync-promote/) -- Composite action to approve and promote resolved patch branches.

See [Upstream Sync](upstream-sync/) for setup and caller examples.

## License

MIT
