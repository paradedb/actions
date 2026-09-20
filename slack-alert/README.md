# Slack Alert

Composite action for posting GitHub Actions alerts to Slack.

Default rendering uses a red attachment with `Repository`, `Workflow`, and `View Logs` fields. Optional inputs can add branch, actor, run ID, custom text, or a complete payload file.

## Usage

Use a dependent GitHub-hosted job with all relevant dependencies when enabling Spot retry suppression:

```yaml
notify-slack-on-failure:
  needs: [build]
  if: always() && needs.build.result == 'failure'
  runs-on: ubuntu-latest
  permissions: # Required for Spot retry detection
    actions: read
    checks: read
  steps:
    - name: Notify Slack on Failure
      uses: paradedb/actions/slack-alert@v14
      with:
        webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
        mention: "<!subteam^S0BLE20RYPM|@pg_search-maintainers>"
        title: "${{ github.workflow }} workflow failed"
        suppress_spot_retries: "true" # Optional; defaults to false
        job_results: ${{ toJSON(needs) }}
```

For a custom Slack body, write JSON to a file and pass `payload_file`.

```yaml
with:
  webhook_url: ${{ secrets.SLACK_GITHUB_CHANNEL_WEBHOOK_URL }}
  payload_file: /tmp/slack-payload.json
```

Inputs: `webhook_url`, `mention`, `title`, `text`, `color`, `payload_file`, `repository`, `branch`, `workflow`, `actor`, `run_id`, `run_url`, `suppress_spot_retries`, `job_results`.

`suppress_spot_retries` requires `job_results` and suppresses alerts for retryable Spot interruptions on attempts 1–2 of the current run. Ordinary failures, exhausted retries, and detector errors still alert. If RunsOn never starts the retry, no fallback alert is sent.
