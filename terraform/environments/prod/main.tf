terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.24" }
    helm       = { source = "hashicorp/helm", version = "~> 2.12" }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "prod"
      Project     = var.project_name
      ManagedBy   = "terraform"
      Owner       = "devops-team"
    }
  }
}

# ─── VPC ───────────────────────────────
module "vpc" {
  source     = "../../modules/vpc"
  project    = var.project_name
  env        = "prod"
  vpc_cidr   = "10.10.0.0/16"
  az_count   = 3
  single_nat = false  # High availability: one NAT per AZ
  tags       = local.tags
}

# ─── EKS ───────────────────────────────
module "eks" {
  source             = "../../modules/eks"
  project            = var.project_name
  env                = "prod"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  kubernetes_version = "1.29"
  allowed_cidrs      = var.allowed_cidrs

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      labels         = { role = "system" }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
    application = {
      instance_types = ["m5.xlarge", "m5a.xlarge"]
      capacity_type  = "SPOT"
      desired_size   = 3
      min_size       = 2
      max_size       = 20
      labels         = { role = "application", workload = "microservices" }
    }
    gpu = {
      instance_types = ["g4dn.xlarge"]
      capacity_type  = "ON_DEMAND"
      desired_size   = 0
      min_size       = 0
      max_size       = 5
      labels         = { role = "gpu" }
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }
  tags = local.tags
}

locals {
  tags = {
    Environment = "prod"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}
