# EKS Module

## Overview

This module creates an Amazon EKS cluster with managed node groups, providing a secure and scalable Kubernetes platform for containerized applications.

## Resources Created

- EKS Cluster with specified Kubernetes version
- Managed Node Groups with auto-scaling
- IAM Roles and Policies for cluster and nodes
- Security Groups for cluster communication
- EKS Add-ons (VPC-CNI, CoreDNS, kube-proxy)
- OIDC Identity Provider for service accounts

## Architecture

```
EKS Cluster (K8s 1.33)
├── Control Plane (AWS Managed)
├── Node Groups
│   ├── Worker Nodes (t3.large)
│   ├── Auto Scaling (1-3 nodes)
│   └── Private Subnets
├── Add-ons
│   ├── VPC-CNI
│   ├── CoreDNS
│   └── kube-proxy
└── Security Groups
    ├── Cluster SG
    └── Node SG
```

## Inputs

| Variable                     | Type         | Description                          | Default              |
| ---------------------------- | ------------ | ------------------------------------ | -------------------- |
| `eks_cluster_name`           | string       | EKS cluster name                     | required             |
| `kubernetes_version`         | string       | Kubernetes version                   | "1.33"               |
| `vpc_id`                     | string       | VPC ID where cluster will be created | required             |
| `private_subnet_ids`         | list(string) | Private subnet IDs for nodes         | required             |
| `public_subnet_ids`          | list(string) | Public subnet IDs for load balancers | required             |
| `eks_endpoint_public_access` | bool         | Enable public API endpoint           | true                 |
| `eks_authentication_mode`    | string       | Authentication mode                  | "API_AND_CONFIG_MAP" |
| `environment`                | string       | Environment name                     | required             |
| `tags`                       | map(string)  | Resource tags                        | {}                   |

## Outputs

| Output                      | Description               |
| --------------------------- | ------------------------- |
| `cluster_id`                | EKS cluster ID            |
| `cluster_arn`               | EKS cluster ARN           |
| `cluster_endpoint`          | EKS cluster endpoint      |
| `cluster_security_group_id` | Cluster security group ID |
| `node_groups`               | Node group information    |
| `oidc_issuer_url`           | OIDC issuer URL           |

## Example Usage

```hcl
module "eks" {
  source = "../modules/eks/"

  eks_cluster_name           = "stackfood-eks"
  kubernetes_version         = "1.33"
  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  public_subnet_ids          = module.vpc.public_subnet_ids
  eks_endpoint_public_access = true
  environment                = "prod"

  tags = {
    Project = "StackFood"
  }
}
```

## Features

- Managed Kubernetes control plane
- Auto-scaling node groups with spot and on-demand instances
- Enhanced security with private worker nodes
- IRSA (IAM Roles for Service Accounts) support
- CloudWatch logging integration
- Encryption at rest for EKS secrets
- Network policy support via Calico

## Security

- Private worker nodes in private subnets
- Security groups with minimal required access
- IAM roles with least privilege principle
- Encryption for etcd and application data
- VPC-native networking with AWS CNI

## Monitoring

- CloudWatch Container Insights enabled
- Prometheus and Grafana compatible
- EKS control plane logging
- Node and pod metrics collection
