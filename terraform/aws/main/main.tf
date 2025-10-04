# VPC Module
module "vpc" {
  source = "../modules/vpc/"

  # General Settings
  vpc_name         = var.vpc_name
  igw_name         = "${var.vpc_name}-igw"
  ngw_name         = "${var.vpc_name}-ngw"
  route_table_name = "${var.vpc_name}-rt"
  environment      = var.environment
  cluster_name     = var.eks_cluster_name
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

# EKS Module - Usando módulo personalizado compatível com AWS Academy
module "eks" {
  source = "../modules/eks/"

  # Configurações básicas do cluster
  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version

  # Configurações de VPC
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # Configuração de IAM (usando a LabRole)
  cluster_role_name = "LabRole"
  node_role_name    = "LabRole"

  # Configurações de endpoint
  endpoint_private_access = true
  endpoint_public_access  = true

  # Configuração de logs
  log_retention_in_days = 30
  log_kms_key_id        = var.eks_kms_key_arn

  # Configuração de criptografia
  kms_key_arn = var.eks_kms_key_arn

  # Configuração dos grupos de nós
  node_groups = {
    api = {
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      instance_types = ["c5.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        "role"                        = "api"
        "node-role.kubernetes.io/api" = "true"
        "app.kubernetes.io/component" = "backend"
        "app.kubernetes.io/part-of"   = "stackfood"
      }
    }
    worker = {
      desired_size   = 2
      max_size       = 3
      min_size       = 2
      instance_types = ["c5.xlarge"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 100
      labels = {
        "role"                           = "worker"
        "node-role.kubernetes.io/worker" = "true"
        "app.kubernetes.io/component"    = "worker"
        "app.kubernetes.io/part-of"      = "stackfood"
      }
    }
  }

  # Configurações de acesso remoto
  enable_remote_management = var.eks_enable_remote_management
  management_cidr_blocks   = var.eks_management_cidr_blocks
  vpc_cidr                 = var.vpc_cidr_blocks[0]

  # Modo de autenticação
  authentication_mode = var.eks_authentication_mode

  # Tags
  environment = var.environment
  tags        = var.tags

  # Dependências
  depends_on = [module.vpc]
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
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  #allowed_security_groups = [module.eks.cluster_security_group_id]
  publicly_accessible = each.value.publicly_accessible

  # Database Settings
  instance_class              = each.value.db_instance_class
  allocated_storage           = each.value.allocated_storage
  max_allocated_storage       = lookup(each.value, "max_allocated_storage", each.value.allocated_storage)
  storage_encrypted           = lookup(each.value, "storage_encrypted", false)
  storage_type                = "gp2"
  db_username                 = each.value.db_username
  db_password                 = lookup(each.value, "db_password", null)                  # Optional password
  manage_master_user_password = lookup(each.value, "manage_master_user_password", false) # Secure password management
  db_name                     = "stackfood"
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

# NGINX Ingress
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

# Lambda Functions
module "lambda" {
  for_each   = var.lambda_functions
  source     = "../modules/lambda/"
  depends_on = [module.vpc]

  # General Settings
  function_name = each.key
  description   = each.value.description
  environment   = var.environment
  tags          = var.tags

  # Bucket para armazenar artefatos da Lambda
  bucket_name = "stackfood-lambda-artifacts"

  # Code and Runtime - condicionalmente baseado no package_type
  package_type     = each.value.package_type
  runtime          = try(each.value.runtime, "dotnet8")
  handler          = each.value.handler
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
  depends_on = [module.eks, module.nginx-ingress, module.acm]

  # General Settings
  api_name    = each.key
  description = each.value.description
  environment = var.environment
  tags        = var.tags

  # Simplified variables for single Lambda and EKS cluster
  eks_cluster_name    = var.eks_cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  acm_certificate_arn = module.acm.certificate_arn

  # New configurable variables
  custom_domain_name  = each.value.custom_domain_name
  stage_name          = each.value.stage_name
  route_key           = each.value.route_key
  security_group_name = each.value.security_group_name
  vpc_link_name       = each.value.vpc_link_name
  cors_configuration  = each.value.cors_configuration
  lambda_invoke_arn   = module.lambda.function_invoke_arn
}

# Cognito Module
module "cognito" {
  source = "../modules/cognito"

  user_pool_name = "stackfood"
  environment    = var.environment

  guest_user_password = "Convidado123!"
}
