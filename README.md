# ☁️ CLOUDSMITH

> Lightweight Terraform-powered AWS infrastructure deployment with PowerShell automation.

![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4?style=for-the-badge\&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?style=for-the-badge\&logo=amazonaws)
![PowerShell](https://img.shields.io/badge/PowerShell-Automation-5391FE?style=for-the-badge\&logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

Deploy AWS infrastructure in minutes using Terraform, with streamlined PowerShell helpers for a clean and beginner-friendly workflow.

---

## 🚀 Features

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

# 🔐 Security Best Practices

### Never Commit

```text
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars
*.pem
.env
```

### Recommended Authentication

Use:

* AWS CLI Profiles
* Environment Variables
* IAM Roles
* AWS Secrets Manager

Avoid hardcoding secrets anywhere in the repository.

---

# 🌍 State Management

This project currently uses:

```text
Local Terraform State
```

Suitable for:

* Learning
* Development
* Testing
* Personal projects

For team environments, migrate to:

* Amazon S3 Backend
* DynamoDB State Locking

Example architecture:

```text
Terraform
    │
    ▼
S3 Backend
    │
    ▼
DynamoDB Lock Table
```

---

# 🧪 Development Workflow

```powershell
terraform fmt
terraform validate
terraform plan
terraform apply
```

Recommended before every commit:

```powershell
terraform fmt -recursive
terraform validate
```

---

# 🔄 Future Enhancements

* [ ] GitHub Actions CI/CD
* [ ] S3 Remote Backend
* [ ] DynamoDB State Locking
* [ ] Multi-Environment Support
* [ ] Terraform Workspaces
* [ ] Module-Based Architecture
* [ ] Infrastructure Testing
* [ ] Cost Estimation Integration

---

# 🤝 Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a Pull Request

Suggestions, bug reports, and improvements are always appreciated.

---

# 📜 License

This project is licensed under the MIT License.

---

<div align="center">

### ☁️ Build • Deploy • Scale

**CLOUDSMITH** — Simple Terraform. Powerful AWS.

</div>
