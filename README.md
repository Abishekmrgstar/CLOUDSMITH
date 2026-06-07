# terraform-aws-deploy

Small Terraform project for deploying AWS infrastructure with helper PowerShell scripts.

## Description

This repository contains a Terraform configuration and PowerShell helper scripts to provision and manage AWS resources. It includes Terraform files (`main.tf`, `providers.tf`, `variables.tf`, `outputs.tf`) and scripts for common workflows (`deploy.ps1`, `plan.ps1`, `destroy.ps1`, `output.ps1`).

## Prerequisites

- Terraform (recommended >= 1.0)
- PowerShell (Windows) or PowerShell Core for other platforms
- AWS credentials configured (e.g. via `aws configure` or environment variables)

## Files

- `main.tf` — primary Terraform configuration
- `providers.tf` — provider configuration (AWS)
- `variables.tf` — variable declarations
- `terraform.tfvars` — variable values (environment-specific)
- `outputs.tf` — Terraform outputs
- `deploy.ps1` — wrapper to run `terraform apply` with recommended args
- `plan.ps1` — wrapper to run `terraform plan` (uses `terraform.tfvars`)
- `destroy.ps1` — wrapper to run `terraform destroy`
- `output.ps1` — wrapper to show Terraform outputs
- `terraform.tfstate`, `terraform.tfstate.backup` — local state files (already present)

## Usage

1. Initialize the working directory:

```powershell
terraform init
```

2. Review the plan (recommended):

```powershell
.\plan.ps1
# or
terraform plan -var-file=terraform.tfvars
```

3. Apply changes to create/update infrastructure:

```powershell
.\deploy.ps1
# or
terraform apply -var-file=terraform.tfvars
```

4. Inspect outputs:

```powershell
.\output.ps1
# or
terraform output
```

5. Destroy resources when no longer needed:

```powershell
.\destroy.ps1
# or
terraform destroy -var-file=terraform.tfvars
```

## Configuration

Edit `terraform.tfvars` to set region, instance types, names, and other settings. Do not commit secrets or sensitive values to version control.

## State

This repository currently stores state locally in `terraform.tfstate`. For team usage, move to a remote state backend (S3 with DynamoDB locking recommended).

## Security & Cleanup

- Keep AWS credentials secure and use least-privilege IAM roles.
- After testing, run `.\destroy.ps1` to remove created resources and avoid charges.

## Next steps

- Move state to an S3 backend with locking for collaboration.
- Add CI/CD to run `terraform fmt`, `terraform validate`, and automated plans.

---

If you'd like, I can run `terraform init` and a dry-run plan, or commit this `README.md` for you.
