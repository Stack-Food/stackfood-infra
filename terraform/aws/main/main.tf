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
  vpc_id          = module.vpc.vpc_id

  # Cluster Settings
  kubernetes_version      = var.kubernetes_version
  endpoint_private_access = true
  endpoint_public_access  = var.eks_endpoint_public_access

  # Node Group Settings
  node_groups = var.eks_node_groups

  # IAM Role Settings
  cluster_role_name = var.eks_cluster_role_name
  node_role_name    = var.eks_node_role_name
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
  allowed_security_groups = [module.eks.node_security_group_id]

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
module "api_lambda" {
  count  = length(local.lambda_functions_with_cognito_refs)
  source = "../modules/lambda/"

  # General Settings
  function_name = local.lambda_functions_with_cognito_refs[count.index].name
  description   = local.lambda_functions_with_cognito_refs[count.index].description
  environment   = var.environment
  tags          = var.tags

  # Code and Runtime
  runtime          = local.lambda_functions_with_cognito_refs[count.index].runtime
  handler          = local.lambda_functions_with_cognito_refs[count.index].handler
  filename         = local.lambda_functions_with_cognito_refs[count.index].filename
  source_code_hash = local.lambda_functions_with_cognito_refs[count.index].source_code_hash

  # Network Settings (VPC)
  vpc_id     = local.lambda_functions_with_cognito_refs[count.index].vpc_access ? module.vpc.vpc_id : null
  subnet_ids = local.lambda_functions_with_cognito_refs[count.index].vpc_access ? module.vpc.private_subnet_ids : []

  # Function Configuration
  memory_size           = local.lambda_functions_with_cognito_refs[count.index].memory_size
  timeout               = local.lambda_functions_with_cognito_refs[count.index].timeout
  environment_variables = local.lambda_functions_with_cognito_refs[count.index].environment_variables

  # IAM Role Settings
  lambda_role_name = var.lambda_role_name

  # Dependencies para garantir que Cognito seja criado primeiro
  depends_on = [module.cognito]
}

# API Gateway
module "api_gateway" {
  for_each = var.api_gateways
  source   = "../modules/api-gateway/"

  # General Settings
  api_name    = each.value.name
  description = each.value.description
  environment = var.environment
  tags        = var.tags

  # Stage Configuration
  stage_name        = each.value.stage_name
  endpoint_type     = each.value.endpoint_type
  create_stage      = true
  stage_description = "API Gateway stage for ${each.value.name}"

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

# Cognito Module
module "cognito" {
  for_each = var.cognito_user_pools
  source   = "../modules/cognito/"

  # General Settings
  user_pool_name = each.value.name
  environment    = var.environment
  tags           = var.tags

  # User Pool Configuration
  alias_attributes         = each.value.alias_attributes
  auto_verified_attributes = each.value.auto_verified_attributes
  username_attributes      = each.value.username_attributes

  # Password Policy
  password_minimum_length          = each.value.password_minimum_length
  password_require_lowercase       = each.value.password_require_lowercase
  password_require_numbers         = each.value.password_require_numbers
  password_require_symbols         = each.value.password_require_symbols
  password_require_uppercase       = each.value.password_require_uppercase
  temporary_password_validity_days = each.value.temporary_password_validity_days

  # Security Settings
  advanced_security_mode       = each.value.advanced_security_mode
  allow_admin_create_user_only = each.value.allow_admin_create_user_only

  # Communication Settings
  email_configuration = each.value.email_configuration
  sms_configuration   = each.value.sms_configuration

  # Lambda Triggers
  lambda_config = each.value.lambda_config

  # Domain Configuration
  domain          = each.value.domain
  certificate_arn = each.value.certificate_arn

  # Client Applications
  clients = each.value.clients

  # Identity Pool Configuration
  create_identity_pool             = each.value.create_identity_pool
  allow_unauthenticated_identities = each.value.allow_unauthenticated_identities
  default_client_key               = each.value.default_client_key
  supported_login_providers        = each.value.supported_login_providers

  # Custom Attributes Schema
  schemas = each.value.schemas

  # Logging
  log_retention_in_days = 7
}
