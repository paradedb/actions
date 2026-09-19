# Slack Alert

Composite action for posting GitHub Actions alerts to Slack.

Default rendering uses a red attachment with `Repository`, `Workflow`, and `View Logs` fields. Optional inputs can add branch, actor, run ID, custom text, or a complete payload file.

## Usage

```yaml
- name: Notify Slack on Failure
  if: failure()
  uses: paradedb/actions/slack-alert@v14
  with:
    webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
    mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
    title: "${{ github.workflow }} workflow failed"
```

For a custom Slack body, write JSON to a file and pass `payload_file`.

```yaml
with:
  webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
  payload_file: /tmp/slack-payload.json
```

Inputs: `webhook_url`, `mention`, `title`, `text`, `color`, `payload_file`, `repository`, `branch`, `workflow`, `actor`, `run_id`, `run_url`.

## RunsOn Spot retries

Set `suppress_spot_retries` to `"true"` to suppress alerts for retryable Spot
interruptions on attempts 1 and 2. Ordinary failures, attempt 3 and later, and
detector errors still send alerts. Suppression is disabled by default.

Use a separate GitHub-hosted notification job so an interrupted runner cannot
prevent detection. Pass all relevant job results and grant read permissions:

```yaml
notify-slack-on-failure:
  needs: [build]
  if: always() && needs.build.result == 'failure'
  runs-on: ubuntu-latest
  permissions:
    actions: read
    checks: read
  steps:
    - uses: paradedb/actions/slack-alert@v14
      with:
        suppress_spot_retries: "true"
        job_results: ${{ toJSON(needs) }}
        webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
```

`github_token` defaults to `github.token` and can be overridden. Detection always
uses the current workflow run; the existing `repository` and `run_id` inputs only
customize the Slack message.

RunsOn schedules retries after the workflow finishes. If a retry never starts,
the suppressed attempt does not send a later fallback alert.
