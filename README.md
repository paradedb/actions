# ParadeDB Actions

Shared GitHub Actions building blocks for ParadeDB repositories.

## Components

- `slack-alert/`: composite action for Slack failure alerts.
- `upstream-sync/`: scripts and docs for keeping a target repo rebased on an upstream repo.
- `.github/workflows/upstream-sync-rebase.yml`: reusable upstream sync rebase workflow.
- `.github/workflows/upstream-sync-promote.yml`: reusable upstream sync promotion workflow.

Reusable workflows must live in `.github/workflows/`; everything else should stay inside the owning component directory.
