# VPC Module

## Overview

This module creates a Virtual Private Cloud (VPC) with public and private subnets across multiple Availability Zones, providing the network foundation for the OptimusFrame infrastructure.

## Resources Created

- VPC with custom CIDR block
- Internet Gateway for public internet access
- NAT Gateways for private subnet internet access (one per AZ)
- Route Tables for public and private subnets
- Subnets (public and private) distributed across AZs
- VPC Endpoints for S3 and other AWS services

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24)
│   ├── Internet Gateway
│   └── Load Balancer, NAT Gateway
└── Private Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
    ├── EKS Nodes
    ├── RDS Database
    └── Application Pods
```

## Inputs

| Variable          | Type         | Description                  | Default  |
| ----------------- | ------------ | ---------------------------- | -------- |
| `vpc_name`        | string       | Name for the VPC             | required |
| `vpc_cidr_blocks` | list(string) | CIDR blocks for VPC          | required |
| `public_subnets`  | map(object)  | Public subnet configuration  | required |
| `private_subnets` | map(object)  | Private subnet configuration | required |
| `environment`     | string       | Environment name             | required |
| `tags`            | map(string)  | Resource tags                | {}       |

## Outputs

| Output                | Description                |
| --------------------- | -------------------------- |
| `vpc_id`              | VPC ID                     |
| `public_subnet_ids`   | List of public subnet IDs  |
| `private_subnet_ids`  | List of private subnet IDs |
| `internet_gateway_id` | Internet Gateway ID        |
| `nat_gateway_ids`     | List of NAT Gateway IDs    |

## Example Usage

```hcl
module "vpc" {
  source = "../modules/vpc/"

  vpc_name        = "OptimusFrame-vpc"
  vpc_cidr_blocks = ["10.0.0.0/16"]
  environment     = "prod"

  public_subnets = {
    "a1" = {
      availability_zone = "us-east-1a"
      cidr_block        = "10.0.101.0/24"
    }
  }

  private_subnets = {
    "a1" = {
      availability_zone = "us-east-1a"
      cidr_block        = "10.0.1.0/24"
    }
  }

  tags = {
    Project = "OptimusFrame"
  }
}
```

## Features

- Multi-AZ deployment for high availability
- Separate routing for public and private subnets
- NAT Gateways for outbound internet access from private subnets
- VPC Flow Logs for network monitoring
- Cost-optimized design with shared NAT Gateways
