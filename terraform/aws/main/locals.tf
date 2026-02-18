locals {
  is_prod = terraform.workspace == "prod"
  is_dev  = terraform.workspace == "dev"
}

# Common tags to be assigned to all resources
locals {
  common_tags = {
    Project     = "OptimusFrame"
    Environment = var.environment
    Terraform   = "true"
    Owner       = "DevOps"
    Workspace   = terraform.workspace
  }
}

locals {
  # Merge common tags with user provided tags
  tags = merge(local.common_tags, var.tags)
}

locals {
  # Security related
  vpc_cidr = var.vpc_cidr_blocks[0]
}

locals {
  # Naming convention
  name_prefix = "${var.environment}-OptimusFrame"
}

