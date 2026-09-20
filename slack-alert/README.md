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

Opt in from a separate GitHub-hosted notification job with all relevant dependencies:

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

Only retryable Spot interruptions on attempts 1–2 suppress alerts; ordinary failures,
exhausted retries, and detector errors still alert. Detection uses the current run.
If RunsOn never starts the retry, no fallback alert is sent.
