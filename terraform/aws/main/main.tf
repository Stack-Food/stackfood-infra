#######################
# Modules & Resources #
#######################

# VPC Module
module "vpc" {
  source = "../modules/vpc/"

  # General Settings
  vpc_name         = var.vpc_name
  igw_name         = "${var.vpc_name}-igw"
  ngw_name         = "${var.vpc_name}-ngw"
  route_table_name = "${var.vpc_name}-rt"
  environment      = var.environment
  tags             = var.tags

  # VPC Settings
  vpc_cidr_blocks        = var.vpc_cidr_blocks
  vpc_enable_dns_support = true
  vpc_enable_dns_hostnames = true

  # Subnet Settings
  subnets_private = var.private_subnets
  subnets_public  = var.public_subnets
}

# EKS Module
module "eks" {
  source = "../modules/eks/"

  # General Settings
  cluster_name = var.eks_cluster_name
  environment  = var.environment
  tags         = var.tags

  # Network Settings
  subnet_ids      = module.vpc.private_subnet_ids
  node_subnet_ids = module.vpc.private_subnet_ids

  # Cluster Settings
  kubernetes_version = var.kubernetes_version
  endpoint_private_access = true
  endpoint_public_access  = var.eks_endpoint_public_access

  # Node Group Settings
  node_groups = var.eks_node_groups
}

# RDS Module
module "rds" {
  source = "../modules/rds/"
  for_each = var.rds_instances

  # General Settings
  identifier   = each.key
  engine       = "postgres"
  engine_version = each.value.engine_version
  environment  = var.environment
  tags         = var.tags

  # Network Settings
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
  allowed_security_groups = [module.eks.node_security_group_id]

  # Database Settings
  instance_class       = each.value.instance_class
  allocated_storage    = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_encrypted    = true

  # Backup and Maintenance
  backup_retention_period = var.db_backup_retention_period
  maintenance_window      = var.db_maintenance_window
  backup_window           = var.db_backup_window

  # Performance and Availability
  multi_az                  = var.db_multi_az
  performance_insights_enabled = true
  deletion_protection       = var.db_deletion_protection
}

# Lambda Functions
module "api_lambda" {
  count  = length(var.lambda_functions)
  source = "../modules/lambda/"

  # General Settings
  function_name = var.lambda_functions[count.index].name
  description   = var.lambda_functions[count.index].description
  environment   = var.environment
  tags          = var.tags

  # Code and Runtime
  runtime          = var.lambda_functions[count.index].runtime
  handler          = var.lambda_functions[count.index].handler
  filename         = var.lambda_functions[count.index].filename
  source_code_hash = var.lambda_functions[count.index].source_code_hash

  # Network Settings (VPC)
  vpc_id     = var.lambda_functions[count.index].vpc_access ? module.vpc.vpc_id : null
  subnet_ids = var.lambda_functions[count.index].vpc_access ? module.vpc.private_subnet_ids : []

  # Function Configuration
  memory_size = var.lambda_functions[count.index].memory_size
  timeout     = var.lambda_functions[count.index].timeout
  environment_variables = var.lambda_functions[count.index].environment_variables
}