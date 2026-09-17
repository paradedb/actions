# ParadeDB Actions

Shared GitHub Actions building blocks for ParadeDB repositories.

## Components

- [build-pg_search-source](build-pg_search-source/) -- Build and stage pg_search from checked-out source.

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
- [upstream-sync](upstream-sync/) -- Reusable workflows for keeping a target repository rebased on an upstream repository.

## License

MIT
