locals {
  is_prod = terraform.workspace == "prod"
  is_dev  = terraform.workspace == "dev"
  
  # Common tags to be assigned to all resources
  common_tags = {
    Project      = "StackFood"
    Environment  = var.environment
    Terraform    = "true"
    Owner        = "DevOps"
    Workspace    = terraform.workspace
  }
  
  # Merge common tags with user provided tags
  tags = merge(local.common_tags, var.tags)
  
  # EKS related
  eks_managed_node_groups_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
  
  # Security related
  vpc_cidr        = var.vpc_cidr_blocks[0]
  
  # Naming convention
  name_prefix     = "${var.environment}-stackfood"
}