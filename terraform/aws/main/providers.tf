terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52.5"
    }
  }

  backend "s3" {
    bucket  = "stackfood-s3-tfstate-fiap"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StackFood"
      Environment = var.environment
      Terraform   = "true"
    }
  }
}

# Configure Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_cluster_name
}

# Configure Kubernetes provider with EKS cluster config
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   command     = "aws"
  #   args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id, "--region", var.aws_region]
  # }
}

# Configure Helm provider with EKS cluster config
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    #token                  = data.aws_eks_cluster_auth.eks.token
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
      command     = "aws"
    }
  }
}
