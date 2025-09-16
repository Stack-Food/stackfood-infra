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
  vpc_cidr_blocks          = var.vpc_cidr_blocks
  vpc_enable_dns_support   = true
  vpc_enable_dns_hostnames = true

  # Subnet Settings
  subnets_private = var.private_subnets
  subnets_public  = var.public_subnets
}

# ACM Certificate Module
module "acm" {
  source = "../modules/acm/"

  # Domain Configuration
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names

  # General Settings
  environment = var.environment
  tags        = var.tags

  # Cloudflare Settings
  cloudflare_zone_id = var.cloudflare_zone_id

  # Validation Settings
  validation_method = "DNS"

  # Certificate Settings
  key_algorithm                   = "RSA_2048"
  transparency_logging_preference = "ENABLED"
}

# EKS Module
module "eks" {
  source = "../modules/eks/"

  # General Settings
  cluster_name        = var.eks_cluster_name
  environment         = var.environment
  tags                = var.tags
  authentication_mode = var.eks_authentication_mode

  # Network Settings
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block

  # Cluster Settings
  kubernetes_version      = var.kubernetes_version
  endpoint_private_access = true
  endpoint_public_access  = var.eks_endpoint_public_access

  # Remote Management Settings
  enable_remote_management = var.eks_enable_remote_management
  management_cidr_blocks   = var.eks_management_cidr_blocks

  # Node Group Settings
  node_groups = var.eks_node_groups

  # IAM Role Settings
  cluster_role_name = var.eks_cluster_role_name
  node_role_name    = var.eks_node_role_name

  log_kms_key_id        = var.eks_log_kms_key_id
  kms_key_arn           = var.eks_kms_key_arn
  log_retention_in_days = var.eks_log_retention_in_days
}

# RDS Module
module "rds" {
  source   = "../modules/rds/"
  for_each = var.rds_instances

  # General Settings
  identifier           = each.key
  engine               = each.value.engine # Use from tfvars for lowercase requirement
  major_engine_version = each.value.major_engine_version
  engine_version       = each.value.engine_version
  environment          = var.environment
  tags                 = var.tags

  # Network Settings
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  allowed_security_groups = [module.eks.cluster_security_group_id]

  # Database Settings
  instance_class              = each.value.db_instance_class
  allocated_storage           = each.value.allocated_storage
  max_allocated_storage       = lookup(each.value, "max_allocated_storage", each.value.allocated_storage)
  storage_encrypted           = lookup(each.value, "storage_encrypted", false)
  storage_type                = "gp2"
  db_username                 = each.value.db_username
  db_password                 = lookup(each.value, "db_password", null)                  # Optional password
  manage_master_user_password = lookup(each.value, "manage_master_user_password", false) # Secure password management

  # IAM Role Settings
  rds_role_name = var.rds_role_name

  # Backup and Maintenance
  backup_retention_period = lookup(each.value, "backup_retention_period", 7)
  maintenance_window      = lookup(each.value, "maintenance_window", "Mon:00:00-Mon:03:00")
  backup_window           = each.value.backup_window

  # Performance and Availability (AWS Academy limitations)
  multi_az                     = lookup(each.value, "multi_az", false)
  performance_insights_enabled = lookup(each.value, "performance_insights_enabled", false)
  deletion_protection          = lookup(each.value, "deletion_protection", false)
}

# Lambda Functions
module "lambda" {
  for_each = var.lambda_functions
  source   = "../modules/lambda/"
  #depends_on = [module.cognito]

  # General Settings
  function_name = each.key
  description   = each.value.description
  environment   = var.environment
  tags          = var.tags

  # Code and Runtime - condicionalmente baseado no package_type
  package_type     = each.value.package_type
  runtime          = try(each.value.runtime, ".NET 8")
  handler          = try(each.value.handler, null)
  filename         = try(each.value.filename, null)
  source_code_hash = try(each.value.source_code_hash, null)
  image_uri        = each.value.image_uri

  # Network Settings (VPC)
  vpc_id     = each.value.vpc_access ? module.vpc.vpc_id : null
  subnet_ids = each.value.vpc_access ? module.vpc.private_subnet_ids : []

  # Function Configuration
  memory_size           = each.value.memory_size
  timeout               = each.value.timeout
  environment_variables = each.value.environment_variables

  # IAM Role Settings
  lambda_role_name = var.lambda_role_name
}

# API Gateway
module "api_gateway" {
  for_each = var.api_gateways
  source   = "../modules/api-gateway/"
  # Dependencies - Garantir que Lambda functions sejam criadas primeiro
  depends_on = [module.lambda, module.eks]

  # General Settings
  api_name    = each.key
  description = each.value.description
  environment = var.environment
  tags        = var.tags

  # Simplified variables for single Lambda and EKS cluster
  aws_region           = var.aws_region
  lambda_function_name = "stackfood-auth" # Single Lambda function name
  eks_cluster_name     = var.eks_cluster_name
  vpc_id               = module.vpc.vpc_id

  # Stage Configuration
  stage_name    = each.value.stage_name
  endpoint_type = each.value.endpoint_type

  # CORS Configuration
  enable_cors            = each.value.enable_cors
  cors_allow_origins     = each.value.cors_allow_origins
  cors_allow_methods     = each.value.cors_allow_methods
  cors_allow_headers     = each.value.cors_allow_headers
  cors_allow_credentials = each.value.cors_allow_credentials

  # Monitoring and Logging
  enable_access_logs    = each.value.enable_access_logs
  xray_tracing_enabled  = each.value.xray_tracing_enabled
  log_retention_in_days = 7

  # Performance
  throttle_settings     = each.value.throttle_settings
  cache_cluster_enabled = each.value.cache_cluster_enabled
  cache_cluster_size    = each.value.cache_cluster_size

  # API Configuration
  resources             = each.value.resources
  methods               = each.value.methods
  integrations          = each.value.integrations
  method_responses      = each.value.method_responses
  integration_responses = each.value.integration_responses

  # API Keys and Usage Plans
  api_keys        = each.value.api_keys
  usage_plans     = each.value.usage_plans
  usage_plan_keys = each.value.usage_plan_keys

  # Lambda Permissions
  lambda_permissions = each.value.lambda_permissions
}


# NGINX Ingres
module "nginx-ingress" {
  source     = "../modules/kubernetes/nginx-ingress"
  depends_on = [module.eks, module.acm]

  ingress_name        = var.nginx_ingress_name
  ingress_repository  = var.nginx_ingress_repository
  ingress_chart       = var.nginx_ingress_chart
  ingress_namespace   = var.nginx_ingress_namespace
  ingress_version     = var.nginx_ingress_version
  ssl_certificate_arn = module.acm.certificate_arn
}

# Cognito Module
# module "cognito" {
#   for_each = var.cognito_user_pools
#   source   = "../modules/cognito/"

#   # General Settings
#   user_pool_name = each.value.name
#   environment    = var.environment
#   tags           = var.tags

#   # User Pool Configuration
#   alias_attributes                              = each.value.alias_attributes
#   auto_verified_attributes                      = each.value.auto_verified_attributes
#   username_attributes                           = each.value.username_attributes
#   attributes_require_verification_before_update = each.value.attributes_require_verification_before_update

#   # Password Policy
#   password_minimum_length          = each.value.password_minimum_length
#   password_require_lowercase       = each.value.password_require_lowercase
#   password_require_numbers         = each.value.password_require_numbers
#   password_require_symbols         = each.value.password_require_symbols
#   password_require_uppercase       = each.value.password_require_uppercase
#   temporary_password_validity_days = each.value.temporary_password_validity_days

#   # Security Settings
#   advanced_security_mode       = each.value.advanced_security_mode
#   allow_admin_create_user_only = each.value.allow_admin_create_user_only

#   # Communication Settings
#   email_configuration = each.value.email_configuration
#   sms_configuration   = each.value.sms_configuration

#   # Lambda Triggers
#   lambda_config = each.value.lambda_config

#   # Domain Configuration
#   domain          = each.value.domain
#   certificate_arn = each.value.certificate_arn

#   # Client Applications
#   clients = each.value.clients

#   # Identity Pool Configuration
#   create_identity_pool             = each.value.create_identity_pool
#   allow_unauthenticated_identities = each.value.allow_unauthenticated_identities
#   default_client_key               = each.value.default_client_key
#   supported_login_providers        = each.value.supported_login_providers

#   # Custom Attributes Schema
#   schemas = each.value.schemas

#   # Logging
#   log_retention_in_days = 7
# }
