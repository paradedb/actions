# ParadeDB GitHub Actions

This repository hosts shared GitHub Actions building blocks for ParadeDB repositories.
Each reusable component should own its docs, scripts, and action metadata in a scoped top-level directory.

## Components

### Upstream Sync

Keeps a target repository rebased on an upstream repository and supports manual promotion of resolved patch branches.

- Docs: [`upstream-sync/README.md`](upstream-sync/README.md)
- Reusable workflows:
  - `.github/workflows/upstream-sync-rebase.yml`
  - `.github/workflows/upstream-sync-promote.yml`
- Supporting scripts: `upstream-sync/scripts/`

The reusable workflow entrypoints live in `.github/workflows/` because GitHub requires reusable workflows to be defined there.
Their filenames are still scoped to the upstream sync component.

### Slack Alert

Posts standardized GitHub Actions failure alerts to Slack.

- Docs: [`slack-alert/README.md`](slack-alert/README.md)
- Action entrypoint: `slack-alert/action.yml`

## Layout

```text
.
|-- .github/workflows/          # Repo CI and reusable workflow entrypoints
|-- slack-alert/                # Composite Slack alert action
`-- upstream-sync/              # Upstream sync docs and supporting scripts
```

When adding a new reusable action, prefer a new top-level directory with its own `action.yml`, implementation files, and README.
