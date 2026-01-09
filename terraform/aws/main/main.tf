# Random ID for unique resource naming
resource "random_id" "bucket_id" {
  byte_length = 4
}

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
  endpoint_private_access = false
  endpoint_public_access  = true

  # Configuração de logs
  log_retention_in_days = 30
  log_kms_key_id        = var.eks_kms_key_arn

  # Configuração de criptografia
  kms_key_arn = var.eks_kms_key_arn

  # Configuração dos grupos de nós
  node_groups = {
    api = {
      desired_size   = 1
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 40
      labels = {
        "role" = "api"
      }
    }
    worker = {
      desired_size   = 1
      max_size       = 3
      min_size       = 1
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      disk_size      = 40
      labels = {
        "role" = "worker"
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
  db_password                 = lookup(each.value, "db_password", null) # Optional password
  manage_master_user_password = false                                   # Secure password management
  db_name                     = lookup(each.value, "db_name", "stackfood")
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

# DynamoDB Tables
module "dynamodb" {
  source   = "../modules/dynamodb/"
  for_each = var.dynamodb_tables

  # General Settings
  table_name  = each.key
  environment = var.environment
  tags        = var.tags

  # Table Keys
  hash_key  = each.value.hash_key
  range_key = lookup(each.value, "range_key", null)

  # Attributes
  attributes = each.value.attributes

  # Billing Mode
  billing_mode   = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  read_capacity  = lookup(each.value, "read_capacity", 5)
  write_capacity = lookup(each.value, "write_capacity", 5)

  # Streams
  stream_enabled   = lookup(each.value, "stream_enabled", false)
  stream_view_type = lookup(each.value, "stream_view_type", "NEW_AND_OLD_IMAGES")

  # TTL
  ttl_enabled        = lookup(each.value, "ttl_enabled", false)
  ttl_attribute_name = lookup(each.value, "ttl_attribute_name", "ttl")

  # Point-in-time Recovery
  point_in_time_recovery_enabled = lookup(each.value, "point_in_time_recovery_enabled", true)

  # Encryption
  encryption_enabled = lookup(each.value, "encryption_enabled", true)
  kms_key_arn        = lookup(each.value, "kms_key_arn", null)

  # Table Class
  table_class = lookup(each.value, "table_class", "STANDARD")

  # Global Secondary Indexes
  global_secondary_indexes = lookup(each.value, "global_secondary_indexes", [])

  # Local Secondary Indexes
  local_secondary_indexes = lookup(each.value, "local_secondary_indexes", [])

  # Autoscaling
  autoscaling_enabled            = lookup(each.value, "autoscaling_enabled", false)
  autoscaling_read_max_capacity  = lookup(each.value, "autoscaling_read_max_capacity", 100)
  autoscaling_write_max_capacity = lookup(each.value, "autoscaling_write_max_capacity", 100)
  autoscaling_read_target_value  = lookup(each.value, "autoscaling_read_target_value", 70)
  autoscaling_write_target_value = lookup(each.value, "autoscaling_write_target_value", 70)

  # CloudWatch Alarms
  create_alarms                  = lookup(each.value, "create_alarms", false)
  alarm_read_throttle_threshold  = lookup(each.value, "alarm_read_throttle_threshold", 10)
  alarm_write_throttle_threshold = lookup(each.value, "alarm_write_throttle_threshold", 10)
}

# SQS Queues
module "sqs" {
  for_each = var.sqs_queues

  source                            = "../modules/sqs"
  queue_name                        = each.key
  queue_name_prefix                 = try(each.value.queue_name_prefix, null)
  fifo_queue                        = try(each.value.fifo_queue, false)
  content_based_deduplication       = try(each.value.content_based_deduplication, true)
  deduplication_scope               = try(each.value.deduplication_scope, null)
  delay_seconds                     = try(each.value.delay_seconds, null)
  fifo_throughput_limit             = try(each.value.fifo_throughput_limit, null)
  kms_master_key_id                 = try(each.value.kms_master_key_id, null)
  kms_data_key_reuse_period_seconds = try(each.value.kms_data_key_reuse_period_seconds, null)
  max_message_size                  = try(each.value.max_message_size, 262144)
  message_retention_seconds         = try(each.value.message_retention_seconds, null)
  receive_wait_time_seconds         = try(each.value.receive_wait_time_seconds, null)
  visibility_timeout_seconds        = try(each.value.visibility_timeout_seconds, null)
  redrive_allow_policy              = try(each.value.redrive_allow_policy, null)
  redrive_policy                    = try(each.value.redrive_policy, null)
  sqs_managed_sse_enabled           = try(each.value.sqs_managed_sse_enabled, false)
  tags                              = try(each.value.tags, {})
  enable_backup_tagging             = try(each.value.enable_backup_tagging, false)

  # Policy configuration
  create_default_policy         = try(each.value.create_default_policy, true)
  policy                        = try(each.value.policy, null)
  allowed_sns_topic_names       = try(each.value.allowed_sns_topic_names, [])
  allowed_lambda_function_names = try(each.value.allowed_lambda_function_names, [])

  # Dead Letter Queue configuration
  create_dlq                    = try(each.value.create_dlq, false)
  dlq_name                      = try(each.value.dlq_name, null)
  max_receive_count             = try(each.value.max_receive_count, null)
  dlq_message_retention_seconds = try(each.value.dlq_message_retention_seconds, null)
  dlq_config                    = try(each.value.dlq_config, null)
}


# SNS Topics
module "sns" {
  source   = "../modules/sns/"
  for_each = var.sns_topics

  # General Settings
  topic_name = each.key
  tags       = merge(var.tags, lookup(each.value, "tags", {}))

  # Topic Configuration
  fifo_topic                  = lookup(each.value, "fifo_topic", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)
  display_name                = lookup(each.value, "display_name", null)

  # Encryption
  kms_master_key_id = lookup(each.value, "kms_master_key_id", null)

  # Policies
  topic_policy    = lookup(each.value, "topic_policy", null)
  delivery_policy = lookup(each.value, "delivery_policy", null)

  # Subscriptions
  sqs_subscriptions   = lookup(each.value, "sqs_subscriptions", {})
  email_subscriptions = lookup(each.value, "email_subscriptions", [])
  https_subscriptions = lookup(each.value, "https_subscriptions", {})

  # Dependencies - garantir que as filas SQS sejam criadas antes das subscriptions
  depends_on = [module.sqs]
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
  bucket_name = "stackfood-lambda-artifacts-${random_id.bucket_id.hex}"

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

# API Gateway HTTP (v2)
module "stackfood_http_api" {

  source     = "../modules/api-gateway-http/"
  name       = "stackfood-http-api"
  depends_on = [module.eks, module.nginx-ingress, module.acm, module.lambda]

  nlb_listener_arn           = module.nginx-ingress.load_balancer-arn
  lb_arn                     = module.nginx-ingress.load_balancer-arn
  cluster_security_group_ids = module.eks.cluster_security_group_id

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # Lambda Integration
  enable_lambda_integration = true
  lambda_invoke_arn         = module.lambda["stackfood-auth"].function_invoke_arn
  lambda_function_name      = module.lambda["stackfood-auth"].function_name

  tags = var.tags
}

# Cognito Module
module "cognito" {
  source = "../modules/cognito"

  user_pool_name = "stackfood"
  environment    = var.environment

  # Configurações do usuário convidado
  create_guest_user   = true
  guest_user_password = "Convidado123!"

  # Configurações do administrador
  stackfood_admin_password = var.argocd_admin_password

  # Configurações dos usuários da equipe
  team_users          = var.team_users
  team_users_password = var.argocd_team_password

  # Configurações ArgoCD OIDC
  argocd_callback_urls = [
    "https://argo.${var.domain_name}/auth/callback"
  ]
  argocd_logout_urls = [
    "https://argo.${var.domain_name}"
  ]

  # Configurações Grafana OIDC
  grafana_callback_urls = [
    "https://grafana.${var.domain_name}/login/generic_oauth"
  ]
  grafana_logout_urls = [
    "https://grafana.${var.domain_name}"
  ]
}

# Módulo ArgoCD com autenticação Cognito
module "argocd" {
  source = "../modules/kubernetes/argocd/"

  # Configurações básicas
  domain_name      = var.domain_name
  argocd_subdomain = "argo"
  environment      = var.environment
  chart_version    = "4.5.2"

  # Configurações Cognito - USANDO O USER POOL ARGOCD DO MÓDULO UNIFICADO
  cognito_user_pool_id      = module.cognito.argocd_user_pool_id
  cognito_client_id         = module.cognito.argocd_client_id
  cognito_client_issuer_url = module.cognito.argocd_issuer_url
  cognito_client_secret     = module.cognito.argocd_client_secret
  cognito_region            = data.aws_region.current.region
  user_pool_name            = module.cognito.argocd_user_pool_name

  # Configurações de grupos
  admin_group_name    = "argocd-admin"
  readonly_group_name = "argocd-readonly"

  # Certificado SSL (opcional)
  certificate_arn = module.acm.certificate_arn

  # Tags
  tags = var.tags

  depends_on = [
    module.cognito,
    module.dns,
    module.eks,
    module.nginx-ingress,
  ]
}

module "dns" {
  source = "../modules/dns/"

  # Configurações básicas
  cloudflare_zone_id = var.cloudflare_zone_id
  domain_name        = var.domain_name
  environment        = var.environment
  eks_cluster_name   = var.eks_cluster_name

  # Configurações ArgoCD
  create_argocd_record = true
  argocd_subdomain     = "argo"

  # Configurações Grafana
  create_grafana_record = true
  grafana_subdomain     = "grafana"

  # DNS Settings
  proxied = true
  ttl     = 300

  # Tags
  tags = var.tags

  depends_on = [module.eks, module.nginx-ingress]
}

# Módulo Grafana com autenticação Cognito
module "grafana" {
  source = "../modules/kubernetes/grafana/"

  # Configurações básicas
  namespace         = "monitoring"
  domain_name       = var.domain_name
  grafana_subdomain = "grafana"
  environment       = var.environment
  chart_version     = "8.5.2"

  # Configurações Cognito - USANDO O MESMO USER POOL DO ARGOCD
  cognito_user_pool_id      = module.cognito.user_pool_id
  cognito_client_id         = module.cognito.grafana_client_id
  cognito_client_secret     = module.cognito.grafana_client_secret
  cognito_region            = data.aws_region.current.region
  cognito_client_issuer_url = module.cognito.grafana_issuer_url
  user_pool_name            = module.cognito.user_pool_name

  # Configurações de grupos do Cognito
  admin_group_name        = "grafana"
  readonly_group_name     = "grafana-readonly"
  system_admin_group_name = "system-admins"

  # Certificado SSL
  certificate_arn = module.acm.certificate_arn

  # Configurações do Prometheus
  prometheus_url               = module.prometheus.prometheus_url
  enable_prometheus_datasource = true

  # Configurações do Loki
  loki_url               = module.loki.loki_url
  enable_loki_datasource = true

  # ⚠️ Configurações de armazenamento (NÃO USADAS - persistence desabilitada)
  # Mantidas para compatibilidade, mas não têm efeito enquanto persistence: false
  # Quando EBS CSI Driver for habilitado, essas configurações voltarão a ser usadas
  storage_size  = "10Gi"
  storage_class = "gp2"

  # Configurações de recursos
  grafana_resources = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
  }

  # Tags
  tags = var.tags

  depends_on = [
    module.cognito,
    module.dns,
    module.eks,
    module.nginx-ingress,
    # module.prometheus,
    # module.loki,
  ]
}

# Prometheus Module - Install before Grafana
# module "prometheus" {
#   source = "../modules/kubernetes/prometheus/"

#   # Basic configuration
#   namespace     = "monitoring"
#   chart_version = "25.27.0"

#   # Retention configuration
#   retention_days = 15

#   # Persistence (disabled for AWS Academy)
#   enable_persistence = false
#   storage_size       = "20Gi"
#   storage_class      = "gp2"

#   depends_on = [module.eks, module.nginx-ingress]
# }

# Loki Module - Install before Grafana
# module "loki" {
#   source = "../modules/kubernetes/loki/"

#   # Basic configuration
#   namespace     = "monitoring"
#   chart_version = "2.10.2"

#   # Retention configuration
#   retention_period = "168h" # 7 days

#   # Persistence (disabled for AWS Academy)
#   enable_persistence = false
#   storage_size       = "10Gi"

#   depends_on = [module.eks, module.nginx-ingress]
# }
