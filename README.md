# 🏗️ Project 2: Infrastructure as Code - AWS Multi-Environment Platform

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-purple)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-Multi--Account-orange)](https://aws.amazon.com)
[![Ansible](https://img.shields.io/badge/Ansible-2.15-red)](https://ansible.com)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Actions Pipeline                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Validate │→│  Lint    │→│  Plan    │→│ Apply (env gate) │  │
│  │ fmt/tflint│ │Checkov  │ │ Comment  │ │ OIDC Auth        │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                     ↓
         ┌───────────────────────┐
         │   AWS Multi-Account   │
         │ ┌───┐ ┌───────┐ ┌───┐│
         │ │DEV│ │STAGING│ │PRD││
         │ └───┘ └───────┘ └───┘│
         └───────────────────────┘
              ↓ Each environment has:
     ┌────────────────────────────────┐
     │  VPC (Multi-AZ)               │
     │  EKS (Managed Node Groups)    │
     │  RDS (Multi-AZ, encrypted)    │
     │  ElastiCache (Redis cluster)  │
     │  ALB + WAF + Shield           │
     │  S3 + CloudFront              │
     │  IAM Roles (OIDC)             │
     └────────────────────────────────┘
```

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Terraform 1.6+ | Infrastructure provisioning |
| AWS Provider 5.x | Cloud resources |
| S3 + DynamoDB | Remote state + locking |
| Ansible 2.15 | Configuration management |
| TFLint | Terraform linting |
| Checkov | Security scanning |
| GitHub Actions OIDC | Keyless AWS auth |

## 🚀 Usage

### Prerequisites
```bash
# Install tools
brew install terraform tflint ansible awscli

# Setup OIDC (no static credentials!)
# Create IAM role with GitHub OIDC trust
aws iam create-role --role-name github-actions-role \
  --assume-role-policy-document file://trust-policy.json
```

### Deploy DEV
```bash
cd terraform/environments/dev
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Configure servers with Ansible
```bash
cd ansible
# Test connectivity
ansible all -i inventories/dev/hosts.ini -m ping

# Run full playbook
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yml

# Run specific role
ansible-playbook -i inventories/dev/hosts.ini playbooks/site.yml --tags docker
```

## 📁 Project Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/          # VPC, subnets, NAT, Flow Logs
│   │   ├── eks/          # EKS cluster + Node Groups + IRSA
│   │   └── rds/          # RDS Multi-AZ + automated backups
│   └── environments/
│       ├── dev/           # 1 NAT GW, smaller instances, spot
│       ├── staging/       # 2 NAT GWs, medium instances
│       └── prod/          # 3 NAT GWs, HA, on-demand + spot mix
├── ansible/
│   ├── roles/
│   │   ├── common/       # Base OS hardening
│   │   ├── docker/       # Docker CE installation
│   │   ├── monitoring/   # Node exporter, Filebeat
│   │   └── security/     # UFW, fail2ban, audit
│   ├── inventories/      # Dynamic AWS inventory
│   └── playbooks/        # site.yml, deploy.yml
└── .github/workflows/
    └── terraform.yml     # Plan on PR, Apply on merge
```

## 🔐 Security Highlights

- GitHub Actions OIDC (no static AWS keys!)
- S3 state encryption + DynamoDB locking
- VPC Flow Logs to CloudWatch
- Private EKS API endpoint in prod
- EKS secrets encrypted with KMS
- Checkov security scanning on every PR
- All resources tagged + drift detection

## 📚 Learning Objectives

1. ✅ Terraform module design patterns
2. ✅ Multi-environment state management
3. ✅ AWS OIDC (keyless CI authentication)
4. ✅ EKS with managed node groups + IRSA
5. ✅ Ansible roles and idempotent playbooks
6. ✅ Security scanning with Checkov + TFLint
7. ✅ Blue-green infrastructure deployment
