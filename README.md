# CLOUDSMITH — Terraform AWS Deployer

Lightweight Terraform starter for provisioning AWS resources with PowerShell helpers.

Why CLOUDSMITH?
- Simple: small, focused Terraform config for quick demos and learning.
- Safe: local-state by default with clear guidance to move to remote backends.
- Portable: PowerShell wrappers make common tasks one-line on Windows and PowerShell Core.

## Quick Start

1. Initialize Terraform:

```powershell
terraform init
```

2. Preview changes (recommended):

```powershell
.\plan.ps1
# or
terraform plan -var-file=terraform.tfvars
```

3. Apply changes:

```powershell
.\deploy.ps1
# or
terraform apply -var-file=terraform.tfvars
```

4. Show outputs:

```powershell
.\output.ps1
# or
terraform output
```

5. Destroy everything when finished:

```powershell
.\destroy.ps1
# or
terraform destroy -var-file=terraform.tfvars
```

## Repository Layout

- `main.tf` — primary Terraform resources
- `providers.tf` — provider configuration
- `variables.tf` — variable declarations
- `terraform.tfvars` — environment-specific values (gitignored)
- `outputs.tf` — exported outputs
- `deploy.ps1`, `plan.ps1`, `destroy.ps1`, `output.ps1` — convenience wrappers
- `.terraform.lock.hcl` — provider lockfile

## Safety & Notes

- This repo currently uses local state files. Do NOT commit `terraform.tfstate` or `terraform.tfstate.backup`.
- For collaboration, migrate state to an S3 backend with DynamoDB locking.
- Keep AWS credentials and secrets out of version control. Use environment variables or secrets manager.

## Suggested Next Steps

- Add a minimal GitHub Actions workflow to run `terraform fmt` and `terraform validate` on PRs.
- Add an S3 backend configuration and a short guide for team usage.

## Contributing

Feel free to open issues or PRs. If you want me to tweak the README, add examples, or include CI, tell me which parts to improve.

---

If you want, I can also rename the repo to `CLOUDSMITH` locally (already pushed) and add a short badge or CI workflow. 
