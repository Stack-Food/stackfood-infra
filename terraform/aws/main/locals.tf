locals {
  is_prod = terraform.workspace == "prod"
  is_dev  = terraform.workspace == "dev"
}

# Common tags to be assigned to all resources
locals {
  common_tags = {
    Project     = "StackFood"
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
  # EKS related
  eks_managed_node_groups_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
}
locals {
  # Security related
  vpc_cidr = var.vpc_cidr_blocks[0]
}
locals {
  # Naming convention
  name_prefix = "${var.environment}-stackfood"
}
locals {
  # Lambda environment variables com referências do Cognito
  lambda_functions_with_cognito_refs = [
    for lambda_func in var.lambda_functions : merge(
      lambda_func,
      {
        environment_variables = merge(
          lambda_func.environment_variables,
          contains(["stackfood-auth-validator", "stackfood-user-creator"], lambda_func.name) ? {
            USER_POOL_ID = length(module.cognito) > 0 ? module.cognito["stackfood-users"].user_pool_id : ""
            CLIENT_ID    = length(module.cognito) > 0 ? module.cognito["stackfood-users"].user_pool_client_ids["cpf-auth-app"] : ""
          } : {}
        )
      }
    )
  ]
}
