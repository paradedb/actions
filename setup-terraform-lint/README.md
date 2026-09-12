# Set Up Terraform Linters

Composite action to install Terraform 1.15.9 and TFLint 0.64.0. Run after checkout on Linux.

## Usage

```yaml
- name: Set Up Terraform Linters
  uses: paradedb/actions/setup-terraform-lint@v12

- name: Check Terraform Formatting
  run: terraform fmt -check -recursive
```

No inputs. The action installs tools only. Each repository owns its `.tflint.hcl`, plugin initialization, working directories, and formatting, validation, and test commands. Keep those steps in the calling workflow.
