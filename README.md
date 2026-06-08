# ☁️ CLOUDSMITH

> Lightweight Terraform-powered AWS infrastructure deployment with 🤖 Claude MCP automation.

![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=for-the-badge&logo=amazonaws)
![Claude MCP](https://img.shields.io/badge/Claude-MCP_Automation-D97757?style=for-the-badge)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=for-the-badge&logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Build and deploy AWS infrastructure through Claude MCP-driven Terraform workflows, enhanced with lightweight PowerShell automation.
---
## 🚀 Features

* 🤖 Claude MCP integration for Terraform planning, deployment, and infrastructure operations
* ⚡ Rapid AWS provisioning with Terraform
* 🛠 PowerShell automation scripts for common operations
* 🔒 Secure infrastructure-as-code practices
* 📦 Simple project structure for learning and demos
* 🌎 Portable across Windows and PowerShell Core environments
* 🎯 Easy migration path to production-grade remote state management

---

## 📋 Prerequisites

Before getting started, ensure you have:

* Terraform installed
* AWS CLI configured
* An AWS account with appropriate permissions
* PowerShell 7+ (recommended)
* Claude desktop

Verify your setup:

```powershell
terraform -version
aws sts get-caller-identity
pwsh --version
```

---

# 🏗 Project Structure

```text
CLOUDSMITH/
│
├── main.tf                 # Infrastructure resources
├── providers.tf            # Provider configuration
├── variables.tf            # Input variables
├── outputs.tf              # Terraform outputs
├── terraform.tfvars        # Environment values (gitignored)
│
├── deploy.ps1              # Apply infrastructure
├── plan.ps1                # Preview changes
├── destroy.ps1             # Remove infrastructure
├── output.ps1              # Display outputs
│
└── .terraform.lock.hcl     # Provider lock file
```

---

# ⚡ Quick Start

## 1. Initialize Terraform

```powershell
terraform init
```

---

## 2. Review Planned Changes

Recommended before every deployment.

```powershell
.\plan.ps1
```

or

```powershell
terraform plan -var-file=terraform.tfvars
```

---

## 3. Deploy Infrastructure

```powershell
.\deploy.ps1
```

or

```powershell
terraform apply -var-file=terraform.tfvars
```

---

## 4. View Outputs

```powershell
.\output.ps1
```

or

```powershell
terraform output
```

---

## 5. Tear Everything Down

When you're finished:

```powershell
.\destroy.ps1
```

or

```powershell
terraform destroy -var-file=terraform.tfvars
```

---

# 🧩 MCP / Claude Integration (GitHub-driven Deploys)

This project is designed so an MCP (like Claude) can detect an application repository, infer required infra, and trigger provisioning. To make that integration smooth, the repo exposes a small automation contract: a set of input variables, expected outputs, and simple scripts that wrap Terraform operations.

What MCP needs to provide:

* `github_repo` — full repo URL or `owner/repo` identifier (example: "https://github.com/Abishekmrgstar/test")
* `github_branch` — branch or tag to deploy (default: `main`)
* AWS credentials — via environment variables, profile, or IAM role
* `aws_region` — AWS region to provision resources in
* Optional deployment hints: `service_type` (ecs|ec2|lambda), `instance_type`, `desired_count`, `domain_name`, and `env_vars` map

Automation contract (inputs & outputs):

- Inputs: `github_repo`, `github_branch`, `aws_region`, `service_type`, `instance_type`, `env_*` variables, and any Terraform-specific variables in `variables.tf`.
- Outputs: Terraform outputs exposed in `outputs.tf` (e.g., `lb_dns`, `instance_public_ip`, `s3_bucket`, `api_endpoint`) which the MCP should read after apply.

Typical flow for an MCP agent:

1. Clone the target repository or accept the `github_repo` value.
2. Populate a `terraform.tfvars` file (or pass `-var` flags) with the required variables.
3. Run `terraform init` then `terraform plan` and `terraform apply` using the included scripts.
4. Read outputs with `terraform output` (or `.\output.ps1`) and report back to the caller.

Example `terraform.tfvars` snippet (MCP can write this):

```hcl
github_repo = "https://github.com/Abishekmrgstar/test"
github_branch = "main"
aws_region = "us-east-1"
service_type = "ecs"
instance_type = "t3.micro"
desired_count = 2
env_name = "staging"
```

Notes for MCP implementers:

* If the repo is a containerized app (Dockerfile present), prefer ECS/Fargate or ECR+ECS flow.
* If the repo is a serverless app (AWS SAM / serverless.yml), use Lambda-based resources.
* If the repo contains build artifacts, MCP can supply a prebuilt `docker_image` value instead of building in-cluster.

---

# 🗣 Example: natural-language prompt mapping

If the agent receives a short, user-facing request such as:

```
need u to deploy this for me https://github.com/Abishekmrgstar/test
```

The MCP should perform these steps automatically:

1. Extract `github_repo` = "https://github.com/Abishekmrgstar/test" from the prompt.
2. Set `github_branch` = `main` (or infer from prompt if provided).
3. Inspect the repository (look for `Dockerfile`, `serverless.yml`, etc.) and infer `service_type`:
	- `Dockerfile` → `service_type = ecs`
	- `serverless.yml` / SAM → `service_type = lambda`
	- otherwise → `service_type = ec2` (fallback)
4. Populate `terraform.tfvars` (or pass `-var` flags) with `github_repo`, `github_branch`, `aws_region`, and other required variables.
5. Run `terraform init`, `terraform plan` and `terraform apply` using the repo scripts.
6. Read Terraform outputs (for example `api_endpoint` or `lb_dns`) and return them to the user.

Sample agent-run commands (what the MCP would run locally):

```powershell
git clone https://github.com/Abishekmrgstar/test /tmp/repo
cd /path/to/terraform-aws-deploy
# write terraform.tfvars with extracted values
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -auto-approve -var-file=terraform.tfvars
terraform output -json
```

This mapping helps ensure that the simple prompt you provided is sufficient for automated deployment.

# 🔧 Expected Terraform variables (summary)

Keep `variables.tf` in sync with what the MCP will provide. Typical variable names used by automation:

* `github_repo` (string)
* `github_branch` (string)
* `aws_region` (string)
* `aws_profile` (string, optional)
* `service_type` (string: ecs|ec2|lambda)
* `instance_type` (string)
* `desired_count` (number)
* `domain_name` (string, optional)
* `vpc_id`, `subnet_ids` (optional)

If you add new variables, document them here and in `variables.tf` so automation can set them.

---

# 🔐 Security & State

This repo uses local state by default which is fine for demos. For production or multi-agent MCP usage, set up a remote backend (S3 + DynamoDB) and restrict credentials. Example backend configuration is listed under `providers.tf` comments.

Never commit secrets or `terraform.tfvars` with secrets to source control.

---

# 🧪 Development Workflow

```powershell
terraform fmt -recursive
terraform validate
.\plan.ps1
.\deploy.ps1
```

Scripts support a `-VarFile` parameter (if provided) or will use `terraform.tfvars` in the repo root. MCP agents can either write a `terraform.tfvars` file or pass variables with `-var`/`-var-file`.

---

# 🔄 Future Enhancements

* [ ] GitHub Actions CI/CD
* [ ] S3 Remote Backend + DynamoDB Locking
* [ ] Multi-Environment Support (workspaces)
* [ ] Module-Based Architecture
* [ ] Infrastructure Testing and Cost Estimation

---

# 🤝 Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

---

# 📜 License

This project is licensed under the MIT License.

---

<div align="center">

### ☁️ Build • Deploy • Scale

**CLOUDSMITH** — Simple Terraform. Powerful AWS.

</div>
