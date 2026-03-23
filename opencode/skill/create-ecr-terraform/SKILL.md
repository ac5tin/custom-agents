---
name: create-ecr-terraform
description: >-
  Scaffold a complete Terraform directory for creating an AWS ECR repository with lifecycle policies,
  backend configuration, and environment-specific tfvars. Use when setting up a new project that needs
  a Docker container registry on AWS, when the user says "create ECR terraform", "set up ECR",
  "scaffold terraform for ECR", or "create terraform infrastructure".
metadata:
  author: fasta
  version: "1.0"
---

# Create ECR Terraform

Scaffold a production-ready Terraform directory that creates an AWS ECR repository with lifecycle policies, S3 backend state management, and environment-specific variable files.

## When to use

- Setting up a new project that needs an ECR repository
- The user asks to create Terraform infrastructure for container registry
- Bootstrapping IaC for a new microservice or application

## Information gathering

Before creating any files, you MUST ask the user for the following values. Do NOT guess or assume defaults unless the user explicitly tells you to use defaults.

| Parameter | Description | Example |
|-----------|-------------|---------|
| **Project name** | Used for tagging and as the default ECR repo name | `myproject` |
| **ECR repository name** | Name of the ECR repository (often same as project name) | `myproject` |
| **S3 backend bucket** | S3 bucket for Terraform state storage | `terraform.fasta.ai` |
| **S3 state key** | Key path within the bucket for the state file | `myproject/dev/terraform.tfstate` |
| **AWS region** | AWS region for resources | `us-east-1` |
| **VPC name** | VPC name for the environment tfvars | `fasta` |
| **Environment** | Environment name | `prod` |
| **EKS cluster name** | EKS cluster name for the environment tfvars | `fasta` |
| **K8s namespace** | Kubernetes namespace for the project | `myproject` |

## Steps

Once all parameters are gathered, create the following directory structure at `./terraform/` in the project root:

```
terraform/
├── backend/
│   └── prod.tfvars
├── env/
│   └── prod.tfvars
├── .gitignore
├── ecr.tf
├── identify.tf
├── Makefile
├── provider.tf
├── README.md
├── vars.tf
└── version.tf
```

### File contents

Create each file with the exact content below, substituting the user-provided values where indicated with `{{PARAMETER}}` placeholders.

#### `terraform/.gitignore`

```
*.hcl
*.tfvars
.terraform
*.tfstate
*.tfstate.backup
```

#### `terraform/ecr.tf`

```hcl

resource "aws_ecr_repository" "this" {
  name = var.aws_ecr_repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire images older than 14 days",
        selection = {
          tagStatus   = "untagged",
          countType   = "sinceImagePushed",
          countUnit   = "days",
          countNumber = 14
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
```

#### `terraform/identify.tf`

```hcl
data "aws_caller_identity" "current" {}
```

#### `terraform/Makefile`

```makefile
.PHONY: init plan apply

TF_ENV ?= dev

init:
	@terraform init -backend-config=backend/$(TF_ENV).tfvars

plan: init
	@terraform plan -refresh=true -var-file=env/$(TF_ENV).tfvars

apply: init
	@terraform apply -refresh=true -var-file=env/$(TF_ENV).tfvars


teardown: init
	@terraform destroy -refresh=true -var-file=env/$(TF_ENV).tfvars
```

#### `terraform/provider.tf`

```hcl
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
      ProjectName = var.project_name
    }
  }
}
```

#### `terraform/version.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.61.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }
  }
}
```

#### `terraform/vars.tf`

```hcl
variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "{{REGION}}"
}

variable "aws_ecr_repository_name" {
  type    = string
  default = "{{ECR_REPOSITORY_NAME}}"
}

variable "project_name" {
  type    = string
  default = "{{PROJECT_NAME}}"
}
```

#### `terraform/backend/prod.tfvars`

```hcl
bucket = "{{S3_BACKEND_BUCKET}}"
key    = "{{S3_STATE_KEY}}"
region = "{{REGION}}"
```

#### `terraform/env/prod.tfvars`

```hcl
vpc_name         = "{{VPC_NAME}}"
environment      = "{{ENVIRONMENT}}"
eks_cluster_name = "{{EKS_CLUSTER_NAME}}"
k8s_namespace    = "{{K8S_NAMESPACE}}"
```

#### `terraform/README.md`

```markdown
# {{PROJECT_NAME}} IaC

#### Plan

```sh
TF_ENV=prod make plan
```

#### Apply

```sh
TF_ENV=prod make apply
```

#### Teardown

```sh
TF_ENV=prod make teardown
```
```

## Post-creation

After creating all files, tell the user:

1. All Terraform files have been created in `./terraform/`
2. Remind them to review the generated files
3. Instruct them to initialize and plan with: `cd terraform && TF_ENV=prod make plan`
4. Instruct them to apply with: `TF_ENV=prod make apply`
5. **NEVER run `terraform apply` or `make apply` yourself. Only the user should run apply.**
6. You MAY run `terraform init` and `terraform plan` (or `make plan`) to verify the configuration if the user asks, but NEVER apply.

## Important constraints

- **NEVER run `terraform apply` or `make apply`** — only plan is allowed
- Always create both `backend/` and `env/` directories with their respective `prod.tfvars` files
- The `.gitignore` ensures tfvars files are not committed (they contain environment-specific config)
- Do not modify or add extra Terraform resources beyond what is specified here unless the user explicitly asks
