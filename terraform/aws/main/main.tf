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

# API Gateway
module "api_gateway" {
  for_each = var.api_gateways
  source   = "../modules/api-gateway/"
  # Dependencies - Garantir que Lambda functions sejam criadas primeiro
  depends_on = [module.eks, module.nginx-ingress, module.acm, module.lambda]

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
  custom_domain_name   = each.value.custom_domain_name
  base_path            = each.value.base_path
  stage_name           = each.value.stage_name
  route_key            = each.value.route_key
  security_group_name  = each.value.security_group_name
  vpc_link_name        = each.value.vpc_link_name
  cors_configuration   = each.value.cors_configuration
  lambda_invoke_arn    = module.lambda["stackfood-auth"].function_invoke_arn
  lambda_function_name = module.lambda["stackfood-auth"].function_name
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

  # Configurações SonarQube OIDC
  sonarqube_callback_urls = [
    "https://sonar.${var.domain_name}/oauth2/callback/oidc"
  ]
  sonarqube_logout_urls = [
    "https://sonar.${var.domain_name}"
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
    module.eks
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

  # Configurações SonarQube
  create_sonarqube_record = true
  sonarqube_subdomain     = "sonar"

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
  prometheus_url               = "http://prometheus-server.monitoring.svc.cluster.local"
  enable_prometheus_datasource = true

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
    module.nginx-ingress
  ]
}

# Módulo SonarQube com autenticação Cognito
module "sonarqube" {
  source = "../modules/kubernetes/sonarqube/"

  # Configurações básicas
  namespace           = "sonarqube"
  domain_name         = var.domain_name
  sonarqube_subdomain = "sonar"
  environment         = var.environment
  chart_version       = "10.7.0+3598"

  # Configurações Cognito - USANDO O MESMO USER POOL
  cognito_user_pool_id      = module.cognito.user_pool_id
  cognito_client_id         = module.cognito.sonarqube_client_id
  cognito_client_secret     = module.cognito.sonarqube_client_secret
  cognito_region            = data.aws_region.current.region
  cognito_client_issuer_url = module.cognito.sonarqube_issuer_url
  user_pool_name            = module.cognito.user_pool_name

  # Configurações de grupos do Cognito
  admin_group_name = "sonarqube"
  user_group_name  = "sonarqube"

  # Certificado SSL
  certificate_arn = module.acm.certificate_arn

  # Configurações de armazenamento
  storage_size  = "20Gi"
  storage_class = "gp2"

  # Configurações de recursos
  sonarqube_resources = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2"
      memory = "8Gi"
    }
  }

  # PostgreSQL configurações - DISABLED (usando RDS externo)
  postgresql_enabled      = false
  postgresql_storage_size = "30Gi"
  postgresql_resources = {
    requests = {
      cpu    = "200m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }

  # RDS PostgreSQL Configuration
  rds_endpoint = module.rds["sonarqube-db"].db_instance_endpoint
  rds_database = "sonarqube"
  rds_username = "sonarqube"
  rds_password = "SonarQube2024!"

  # Monitoring
  monitoring_passcode = "stackfood-sonar-monitoring"

  depends_on = [
    module.cognito,
    module.dns,
    module.eks,
    module.nginx-ingress,
    module.rds
  ]
}
