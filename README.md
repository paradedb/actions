# Upstream Sync Shared Actions

This repository hosts the centralized logic for synchronizing "target" repositories with their "upstream" repositories.

By centralizing the logic here, individual repositories (like `paradedb-enterprise` or any other destination) only need to include a tiny wrapper script and minimal GitHub Action workflows that point to this repository.

## Components

### `scripts/sync-core.sh`

This is the unified bash script that handles the heavy lifting of Git operations (fetching, checking out patch branches, rebasing commits one by one) and polling GitHub CI.

It expects the following environment variables to be set by the caller (usually the wrapper script in the target repository):

- `UPSTREAM_REPO`: (e.g., `paradedb/paradedb`)
- `UPSTREAM_REPO_URL`: (e.g., `https://github.com/paradedb/paradedb.git`)
- `TARGET_REPO`: (e.g., `paradedb/paradedb-enterprise`)
- `TARGET_BRANCH`: Defaults to `main`
- `UPSTREAM_BRANCH`: Defaults to `main`

### `.github/workflows/reusable-rebase.yml`

A Reusable Workflow that runs on a schedule in the target repository. It automatically checks out the target repository and invokes its local wrapper script to perform the rebase. If conflicts occur, it notifies Slack.

### `.github/workflows/reusable-promote.yml`

A Reusable Workflow that requires manual approval to merge a resolved patch branch into the target branch.

## How to use in a new repository

To set up Upstream Sync in a new target repository, follow these steps:

**Step 1: Copy the wrapper script**
Copy the wrapper script `scripts/sync-upstream.sh` into your target repository and make it executable.

**Step 2: Edit environment variables**
Edit the environment variables in `sync-upstream.sh` to point to your specific upstream and target repositories. Replace the placeholder values with explicit strings for your repository setup. For example:

```bash
export UPSTREAM_REPO="paradedb/paradedb"
export UPSTREAM_REPO_URL="https://github.com/paradedb/paradedb.git"
export TARGET_REPO="paradedb/paradedb-enterprise"
export TARGET_BRANCH="main"
export UPSTREAM_BRANCH="main"
```

> [!NOTE]
> The reusable workflows (`reusable-promote.yml`) will `source` your script to dynamically extract these variables to populate Git commands in GitHub issues. Make sure they are `export`ed.

**Step 3: Add proxy workflows**
Add the tiny proxy GitHub Action workflows to your `.github/workflows/` directory that `uses:` the reusable workflows in this repository.
You must pass the `github_app_client_id` input (usually from a repository variable) to both reusable workflows. For `reusable-promote.yml`, also pass the `approvers` input.

**Step 4: Configure GitHub Secrets and Variables**
The reusable workflows require a GitHub App token to perform commits and create pull requests. Ensure the target repository has the following configured:

- **Variables (`vars.*`)**:
  - `PARADEDB_GITHUB_APP_CLIENT_ID` (Required): The Client ID of the GitHub App. You will pass this as the `github_app_client_id` input.
  - `USERNAME_MAPPING_GITHUB_TO_SLACK` (Optional): A JSON mapping of GitHub usernames to Slack Member IDs.
- **Secrets (`secrets.*`)**:
  - `PARADEDB_GITHUB_APP_PRIVATE_KEY` (Required): The Private Key of the GitHub App.
  - `SLACK_WEBHOOK_URL` (Optional): A Slack webhook URL to notify on rebase/promotion failures.

> [!NOTE]
> Ensure you pass `secrets: inherit` in the caller workflow so that the reusable workflows can access these secrets.

For an example of how this is consumed, see the setup in the `paradedb/paradedb-enterprise` repository.
