# Upstream Sync

This component hosts the centralized logic for synchronizing target repositories with their upstream repositories.

By centralizing the logic here, target repositories such as `paradedb/paradedb-enterprise` only need a small wrapper script and minimal GitHub Actions workflows that point to this repository.

## Components

### `upstream-sync/scripts/sync-core.sh`

The unified Bash script that handles the heavy lifting of Git operations, including fetching, checking out patch branches, rebasing commits one by one, and polling GitHub CI.

It expects the following environment variables to be set by the caller, usually the wrapper script in the target repository:

- `UPSTREAM_REPO`: for example, `paradedb/paradedb`
- `UPSTREAM_REPO_URL`: for example, `https://github.com/paradedb/paradedb.git`
- `TARGET_REPO`: for example, `paradedb/paradedb-enterprise`
- `TARGET_BRANCH`: defaults to `main`
- `UPSTREAM_BRANCH`: defaults to `main`

### `.github/workflows/upstream-sync-rebase.yml`

A reusable workflow that runs on a schedule in the target repository.
It checks out the target repository and invokes its local wrapper script to perform the rebase.
If conflicts occur, it notifies Slack.

### `.github/workflows/upstream-sync-promote.yml`

A reusable workflow that requires manual approval to merge a resolved patch branch into the target branch.

## How To Use

### Step 1: Copy The Wrapper Script

Copy `upstream-sync/scripts/sync-upstream.sh` into your target repository as `scripts/sync-upstream.sh` and make it executable.

### Step 2: Edit Environment Variables

Edit the environment variables in `scripts/sync-upstream.sh` to point to your upstream and target repositories.
Replace the placeholder values with explicit strings for your repository setup.

```bash
export UPSTREAM_REPO="paradedb/paradedb"
export UPSTREAM_REPO_URL="https://github.com/paradedb/paradedb.git"
export TARGET_REPO="paradedb/paradedb-enterprise"
export TARGET_BRANCH="main"
export UPSTREAM_BRANCH="main"
```

The reusable workflows source your script to dynamically extract these variables for GitHub issues and Git commands, so make sure they are exported.

### Step 3: Add Proxy Workflows

Add small proxy workflows to the target repository that call the reusable workflows from this repository.

```yaml
jobs:
  upstream-rebase:
    uses: paradedb/actions/.github/workflows/upstream-sync-rebase.yml@v10
    with:
      github_app_client_id: ${{ vars.PARADEDB_GITHUB_APP_CLIENT_ID }}
      approvers: "philippemnoel,rebasedming,stuhood,mdashti"
      slack_alert_mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
    secrets:
      SLACK_WEBHOOK_URL: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
      PARADEDB_GITHUB_APP_PRIVATE_KEY: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
```

For promotion workflows, use `.github/workflows/upstream-sync-promote.yml@v10`.
You must pass the `github_app_client_id` input to both reusable workflows.
You must also pass the `approvers` input to both workflows to configure fallback Slack notifications and manual approval.

For `upstream-sync-rebase.yml`, you may also pass `slack_alert_mention` with a Slack mention such as `<!subteam^ID|@group>` as a final fallback after actor and approver mappings.

### Step 4: Configure GitHub Secrets And Variables

The reusable workflows require a GitHub App token to perform commits and create pull requests.
Ensure the target repository has the following configured:

- Variables:
  - `PARADEDB_GITHUB_APP_CLIENT_ID`: The Client ID of the GitHub App.
  - `USERNAME_MAPPING_GITHUB_TO_SLACK`: Optional mapping of GitHub usernames to Slack member IDs.
- Secrets:
  - `PARADEDB_GITHUB_APP_PRIVATE_KEY`: The private key of the GitHub App.
  - `SLACK_WEBHOOK_URL`: Optional Slack webhook URL to notify on rebase or promotion failures.

Ensure you explicitly map the secrets in the caller workflow so that the reusable workflows can access them.

```yaml
secrets:
  SLACK_WEBHOOK_URL: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
  PARADEDB_GITHUB_APP_PRIVATE_KEY: ${{ secrets.PARADEDB_GITHUB_APP_PRIVATE_KEY }}
```

For an example of how this is consumed, see the setup in the `paradedb/paradedb-enterprise` repository.
