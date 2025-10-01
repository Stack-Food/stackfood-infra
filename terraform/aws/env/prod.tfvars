aws_region  = "us-east-1"
environment = "prod"

tags = {
  Project    = "StackFood"
  Team       = "DevOps"
  CostCenter = "IT"
}

######################
# Domain Configuration #
######################
domain_name               = "stackfood.com.br"
subject_alternative_names = ["*.stackfood.com.br"]

# DNS Provider Configuration (Cloudflare)
cloudflare_zone_id = "09f31a057e454d7d71ab44b6b5960723" # Substitua pelo seu Zone ID real

######################
# VPC Configuration #
######################
vpc_name        = "stackfood-prod-vpc"
vpc_cidr_blocks = ["10.0.0.0/16"]

private_subnets = {
  "private1" = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.1.0/24"
  },
  "private2" = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.2.0/24"
  },
  "private3" = {
    availability_zone = "us-east-1c"
    cidr_block        = "10.0.3.0/24"
  }
}

public_subnets = {
  "public1" = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.101.0/24"
  },
  "public2" = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.102.0/24"
  },
  "public3" = {
    availability_zone = "us-east-1c"
    cidr_block        = "10.0.103.0/24"
  }
}

######################
# Load Balancer Configuration #
######################



######################
# EKS Configuration #
######################
eks_cluster_name           = "stackfood-prod-eks"
kubernetes_version         = "1.33"
eks_endpoint_public_access = true
eks_authentication_mode    = "API_AND_CONFIG_MAP"

# Remote Management Configuration
eks_enable_remote_management = true
eks_management_cidr_blocks   = ["0.0.0.0/0"] # Ajuste para seu IP específico em produção


########################
# NGINX Ingress Configuration # 
########################
nginx_ingress_name       = "ingress-nginx"
nginx_ingress_repository = "https://kubernetes.github.io/ingress-nginx"
nginx_ingress_chart      = "ingress-nginx"
nginx_ingress_namespace  = "ingress-nginx"
nginx_ingress_version    = "4.10.0"

######################
# RDS Configuration #
######################
rds_instances = {
  "stackfood-prod-db" = {
    # AWS Academy compliant settings
    allocated_storage            = 20            # Changed from 50 to 20 (within 100GB limit)
    storage_encrypted            = false         # Simplified for AWS Academy
    db_instance_class            = "db.t3.micro" # Changed to supported instance type
    db_username                  = "stackfood"
    db_password                  = "postgres" # Ensure this meets complexity requirements
    manage_master_user_password  = false
    engine                       = "postgres" # Lowercase as required
    engine_version               = "16.3"     # Updated version
    major_engine_version         = "16"
    identifier                   = "stackfood-prod-postgres"
    publicly_accessible          = true
    multi_az                     = false # Disabled for cost savings
    performance_insights_enabled = false # Enhanced monitoring not supported
    port                         = 5432
    backup_window                = "03:00-06:00"
    maintenance_window           = "Mon:00:00-Mon:03:00"
    deletion_protection          = false
    backup_retention_period      = 7
  }
}

######################
# IAM Configuration #
######################
lambda_role_name      = "LabRole"
eks_cluster_role_name = "LabRole"
eks_node_role_name    = "LabRole"
rds_role_name         = "LabRole"

######################
# Lambda Configuration #
######################
lambda_functions = {
  "stackfood-auth" = {
    description  = "Lambda for CPF authentication and JWT validation"
    package_type = "Zip"
    # Imagem base oficial AWS Lambda para .NET 8 - RUNTIME
    memory_size = 256
    runtime     = "dotnet8"
    timeout     = 30
    vpc_access  = false
    handler     = "index.handler"
    filename    = "function.zip"
    environment_variables = {
      USER_POOL_ID           = ""
      CLIENT_ID              = ""
      LOG_LEVEL              = "info"
      ASPNETCORE_ENVIRONMENT = "Production"
    }
  }
}

##########################
# API Gateway Configuration #
##########################

api_gateways = {
  "stackfood-api" = {
    description         = "StackFood API Gateway for production environment"
    custom_domain_name  = "api.stackfood.com.br"
    stage_name          = "v1"
    route_key           = "ANY /{proxy+}"
    security_group_name = "stackfood-prod-api-gateway-vpc-link-sg"
    vpc_link_name       = "stackfood-prod-api-gateway-vpc-link"
    cors_configuration = {
      allow_credentials = false
      allow_headers     = ["*"]
      allow_methods     = ["*"]
      allow_origins     = ["*"]
      expose_headers    = ["*"]
      max_age           = 86400
    }
  }
} ##########################
# Cognito Configuration #
##########################
cognito_user_pools = {
  "stackfood-users" = {
    name                                          = "stackfood-prod-users"
    alias_attributes                              = ["preferred_username"] # CPF será usado via preferred_username
    auto_verified_attributes                      = []                     # Sem verificação automática (apenas CPF)
    attributes_require_verification_before_update = []                     # Nenhum atributo requer verificação antes de atualizar
    # Para autenticação por CPF customizada, usar alias_attributes em vez de username_attributes

    # Password Policy - Desabilitada para autenticação sem senha
    password_minimum_length          = 8 # Mantido para compatibilidade, mas não será usado
    password_require_lowercase       = false
    password_require_numbers         = false
    password_require_symbols         = false
    password_require_uppercase       = false
    temporary_password_validity_days = 1

    # Security Settings - Configurado para autenticação customizada
    advanced_security_mode       = "AUDIT" # Mudado para AUDIT para permitir auth customizada
    allow_admin_create_user_only = true    # Apenas admin pode criar (via Lambda)

    # Email Configuration - Opcional para este fluxo
    email_configuration = {
      email_sending_account = "COGNITO_DEFAULT"
    }

    # Lambda Triggers para autenticação customizada com CPF
    lambda_config = {
      create_auth_challenge          = null # Lambda para criar desafio personalizado (CPF)
      define_auth_challenge          = null # Lambda para definir fluxo de autenticação
      verify_auth_challenge_response = null # Lambda para verificar CPF
      pre_sign_up                    = null # Lambda para pré-processamento de registro
      post_confirmation              = null # Lambda para pós-confirmação
      post_authentication            = null # Lambda para pós-autenticação
    }

    # Domain for hosted UI (opcional para POC)
    domain = "stackfood-prod"

    # Client Applications - Configurado para autenticação sem senha
    clients = {
      "cpf-auth-app" = {
        name                         = "stackfood-cpf-auth"
        generate_secret              = false # Frontend não precisa de secret
        refresh_token_validity       = 30
        access_token_validity        = 60
        id_token_validity            = 60
        access_token_validity_units  = "minutes"
        id_token_validity_units      = "minutes"
        refresh_token_validity_units = "days"

        # OAuth flows para SPA com autenticação customizada
        allowed_oauth_flows                  = ["implicit"]
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_scopes                 = ["openid", "profile", "aws.cognito.signin.user.admin"]
        callback_urls                        = ["http://localhost:3000/callback", "https://stackfood-prod.com/callback"]
        logout_urls                          = ["http://localhost:3000/logout", "https://stackfood-prod.com/logout"]

        # Autenticação customizada para CPF sem senha
        explicit_auth_flows           = ["ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
        supported_identity_providers  = ["COGNITO"]
        prevent_user_existence_errors = "ENABLED"
        enable_token_revocation       = true

        read_attributes  = []
        write_attributes = []
      }

      "api-backend" = {
        name                         = "stackfood-api-backend"
        generate_secret              = true # Backend precisa de secret
        refresh_token_validity       = 30
        access_token_validity        = 120 # Maior validade para API
        id_token_validity            = 60
        access_token_validity_units  = "minutes"
        id_token_validity_units      = "minutes"
        refresh_token_validity_units = "days"

        # Client credentials para serviços backend
        allowed_oauth_flows                  = ["client_credentials"]
        allowed_oauth_flows_user_pool_client = true
        allowed_oauth_scopes                 = ["aws.cognito.signin.user.admin"]

        # Permite autenticação administrativa para criação de usuários
        explicit_auth_flows           = ["ALLOW_ADMIN_USER_PASSWORD_AUTH", "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
        supported_identity_providers  = ["COGNITO"]
        prevent_user_existence_errors = "ENABLED"
        enable_token_revocation       = true

        read_attributes  = []
        write_attributes = []
      }
    }

    # Identity Pool para acesso AWS (opcional)
    create_identity_pool             = true
    allow_unauthenticated_identities = false
    default_client_key               = "cpf-auth-app"

    # Custom Attributes para StackFood - Foco em CPF
    schemas = [
      {
        attribute_data_type      = "String"
        name                     = "custom:cpf"
        required                 = false # Custom attributes não podem ser required
        mutable                  = false # CPF não pode ser alterado
        developer_only_attribute = false
        string_attribute_constraints = {
          min_length = "11"
          max_length = "14"
        }
      }
    ]
  }
}
