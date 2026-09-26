# Set Up Git Signing

Configure SSH commit and tag signing in the checked-out repository. Requires `git`, `ssh-keygen`, and an authenticated `gh` CLI token. The action verifies that the public key is registered as a signing key on the specified GitHub account.

```yaml
- name: Configure Git Signing
  uses: paradedb/actions/setup-git-signing@v14
  with:
    github-token: ${{ steps.app-token.outputs.token }}
    signing-key: ${{ secrets.PARADEDB_GITHUB_BOT_COMMIT_SIGNING_KEY }}
    signing-user: ${{ secrets.PARADEDB_GITHUB_BOT_COMMIT_SIGNING_USER }}
    signing-email: ${{ secrets.PARADEDB_GITHUB_BOT_COMMIT_SIGNING_EMAIL }}

# Create signed commits or tags here.

- name: Remove Signing Key
  if: always()
  shell: bash
  run: rm -f "$RUNNER_TEMP/github-bot-signing-key" "$RUNNER_TEMP/github-bot-signing-key.allowed-signers"
```

Use an unencrypted OpenSSH private key and a verified email address for the signing account. Callers must remove the temporary key and allowed-signers file in an `always()` cleanup step after signing finishes.
