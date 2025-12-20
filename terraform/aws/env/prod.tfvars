aws_region  = "us-east-1"
environment = "prod"

tags = {
  Project = "StackFood"
  Team    = "SOAT-FIAP"
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
vpc_name        = "stackfood-vpc"
vpc_cidr_blocks = ["10.0.0.0/16"]

private_subnets = {
  "a1" = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.1.0/24"
  },
  "b2" = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.2.0/24"
  },
  "c3" = {
    availability_zone = "us-east-1c"
    cidr_block        = "10.0.3.0/24"
  }
}

public_subnets = {
  "a1" = {
    availability_zone = "us-east-1a"
    cidr_block        = "10.0.101.0/24"
  },
  "b2" = {
    availability_zone = "us-east-1b"
    cidr_block        = "10.0.102.0/24"
  },
  "c3" = {
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
eks_cluster_name           = "stackfood-eks"
kubernetes_version         = "1.34"
eks_endpoint_public_access = true
eks_authentication_mode    = "API_AND_CONFIG_MAP"

# Remote Management Configuration
eks_enable_remote_management = true
eks_management_cidr_blocks   = ["0.0.0.0/0"]

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
  "stackfood-db" = {
    # AWS Academy compliant settings
    allocated_storage            = 20            # Changed from 50 to 20 (within 100GB limit)
    storage_encrypted            = false         # Simplified for AWS Academy
    db_instance_class            = "db.t3.micro" # Changed to supported instance type
    db_username                  = "stackfood"
    db_password                  = "postgres" # Ensure this meets complexity requirements
    manage_master_user_password  = false
    engine                       = "postgres" # Lowercase as required
    engine_version               = "16.10"    # Valid PostgreSQL 16 version
    major_engine_version         = "16"
    identifier                   = "stackfood-postgres"
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
eks_cluster_role_name = "LabRole"
rds_role_name         = "LabRole"
lambda_role_name      = "LabRole"

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
    vpc_access  = true
    handler     = "StackFood.Lambda::StackFood.Lambda.Function::FunctionHandler"
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
    base_path           = "v1" # Empty for root path, or specify a path like "v1" for api.domain.com/v1
    stage_name          = "v1"
    route_key           = "ANY /{proxy+}"
    security_group_name = "stackfood-api-gateway-vpc-link-sg"
    vpc_link_name       = "stackfood-api-gateway-vpc-link"
    cors_configuration = {
      allow_credentials = false
      allow_headers     = ["*"]
      allow_methods     = ["*"]
      allow_origins     = ["*"]
      expose_headers    = ["*"]
      max_age           = 86400
    }
  }
}
##########################
# Cognito Configuration #
##########################
cognito_user_pools = {
  "stackfood-users" = {
    name                                          = "stackfood-users"
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
    domain = "stackfood-users-domain"

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
        callback_urls                        = ["http://localhost:3000/callback", "https://stackfood.com.br/callback"]
        logout_urls                          = ["http://localhost:3000/logout", "https://stackfood.com.br/logout"]

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

######################
# ArgoCD Users Configuration #
######################

# Usuários da equipe StackFood para ArgoCD
team_users = {
  "leonardo.duarte" = {
    name      = "Leonardo Duarte"
    email     = "leo.duarte.dev@gmail.com"
    user_type = "developer"
    groups    = ["argocd", "grafana"]
  }
  "luiz.felipe" = {
    name      = "Luiz Felipe Maia"
    email     = "luiz.felipeam@hotmail.com"
    user_type = "developer"
    groups    = ["argocd", "grafana", "system-admins"]
  }
  "leonardo.lemos" = {
    name      = "Leonardo Luiz Lemos"
    email     = "leoo_lemos@outlook.com"
    user_type = "developer"
    groups    = ["argocd", "grafana"]
  }
  "rodrigo.silva" = {
    name      = "Rodrigo Rodriguez Figueiredo de Oliveira Silva"
    email     = "rodrigorfig1@gmail.com"
    user_type = "developer"
    groups    = ["argocd", "grafana"]
  }
  "vinicius.targa" = {
    name      = "Vinicius Targa Gonçalves"
    email     = "viniciustarga@gmail.com"
    user_type = "developer"
    groups    = ["argocd", "grafana"]
  }
}

# Senhas para usuários
argocd_admin_password = "Fiap@2025"
argocd_team_password  = "StackFood@2025"



################
# Grafana Configuration #
################

# Configurações específicas do Grafana
grafana_subdomain     = "grafana"
grafana_storage_size  = "10Gi"
grafana_storage_class = "gp2"

# Configurações de recursos do Grafana
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

# URL do Prometheus (ajuste conforme sua instalação)
prometheus_url = "http://prometheus-server.monitoring.svc.cluster.local"

# Habilitar datasource automático do Prometheus
enable_prometheus_datasource = true

# Namespace para instalação
monitoring_namespace = "monitoring"


############
### SQS ####
############
sqs_queues = {
  # Orders API Queue
  "stackfood-sqs-orders-created-queue" = {
    fifo_queue                  = false
    content_based_deduplication = true
    deduplication_scope         = null
    fifo_throughput_limit       = null
    delay_seconds               = 0
    message_retention_seconds   = 1209600
    max_message_size            = 262144
    visibility_timeout_seconds  = 300
    receive_wait_time_seconds   = 5
    sqs_managed_sse_enabled     = true
    create_default_policy       = true

    # DLQ Configuration
    create_dlq        = true
    dlq_name          = "stackfood-sqs-orders-created-dlq"
    max_receive_count = 5

    # Custom DLQ Configuration Object 
    dlq_config = {
      delay_seconds              = 0
      max_message_size           = 262144
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 0
      visibility_timeout_seconds = 30

      sqs_managed_sse_enabled           = true
      kms_master_key_id                 = null
      kms_data_key_reuse_period_seconds = 300

      content_based_deduplication = false
      deduplication_scope         = null
      fifo_throughput_limit       = null

      redrive_allow_policy = null
      policy               = null

      tags = {
        ManagedBy = "Terraform"
        API       = "orders"
      }
    }

    redrive_allow_policy = {
      redrivePermission = "allowAll"
    }
    tags = {
      ManagedBy = "Terraform"
      API       = "orders"
    }
  },

  "stackfood-sqs-orders-cancelled-queue" = {
    fifo_queue                  = false
    content_based_deduplication = true
    deduplication_scope         = null
    fifo_throughput_limit       = null
    delay_seconds               = 0
    message_retention_seconds   = 1209600
    max_message_size            = 262144
    visibility_timeout_seconds  = 300
    receive_wait_time_seconds   = 5
    sqs_managed_sse_enabled     = true
    create_default_policy       = true

    # DLQ Configuration
    create_dlq        = true
    dlq_name          = "stackfood-sqs-orders-cancelled-dlq"
    max_receive_count = 5

    # Custom DLQ Configuration Object 
    dlq_config = {
      delay_seconds              = 0
      max_message_size           = 262144
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 0
      visibility_timeout_seconds = 30

      sqs_managed_sse_enabled           = true
      kms_master_key_id                 = null
      kms_data_key_reuse_period_seconds = 300

      content_based_deduplication = false
      deduplication_scope         = null
      fifo_throughput_limit       = null

      redrive_allow_policy = null
      policy               = null

      tags = {
        ManagedBy = "Terraform"
        API       = "orders"
      }
    }

    redrive_allow_policy = {
      redrivePermission = "allowAll"
    }
    tags = {
      ManagedBy = "Terraform"
      API       = "orders"
    }
  }

  # Payments API Queue
  "stackfood-sqs-orders-completed-queue" = {
    fifo_queue                  = false
    content_based_deduplication = true
    deduplication_scope         = null
    fifo_throughput_limit       = null
    delay_seconds               = 0
    message_retention_seconds   = 1209600
    max_message_size            = 262144
    visibility_timeout_seconds  = 300
    receive_wait_time_seconds   = 5
    sqs_managed_sse_enabled     = true
    create_default_policy       = true

    create_dlq        = true
    dlq_name          = "stackfood-sqs-orders-completed-dlq"
    max_receive_count = 5

    dlq_config = {
      delay_seconds              = 0
      max_message_size           = 262144
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 0
      visibility_timeout_seconds = 30

      sqs_managed_sse_enabled           = true
      kms_master_key_id                 = null
      kms_data_key_reuse_period_seconds = 300

      content_based_deduplication = false
      deduplication_scope         = null
      fifo_throughput_limit       = null

      redrive_allow_policy = null
      policy               = null

      tags = {
        ManagedBy = "Terraform"
        API       = "Orders"
      }
    }

    redrive_allow_policy = {
      redrivePermission = "allowAll"
    }
    tags = {
      ManagedBy = "Terraform"
      API       = "payments"
    }
  }

  # Products API Queue
  "stackfood-sqs-products-queue" = {
    fifo_queue                  = false
    content_based_deduplication = true
    deduplication_scope         = null
    fifo_throughput_limit       = null
    delay_seconds               = 0
    message_retention_seconds   = 1209600
    max_message_size            = 262144
    visibility_timeout_seconds  = 300
    receive_wait_time_seconds   = 5
    sqs_managed_sse_enabled     = true
    create_default_policy       = true

    create_dlq        = true
    dlq_name          = "stackfood-sqs-products-dlq"
    max_receive_count = 5

    dlq_config = {
      delay_seconds              = 0
      max_message_size           = 262144
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 0
      visibility_timeout_seconds = 30

      sqs_managed_sse_enabled           = true
      kms_master_key_id                 = null
      kms_data_key_reuse_period_seconds = 300

      content_based_deduplication = false
      deduplication_scope         = null
      fifo_throughput_limit       = null

      redrive_allow_policy = null
      policy               = null

      tags = {
        ManagedBy = "Terraform"
        API       = "products"
      }
    }

    redrive_allow_policy = {
      redrivePermission = "allowAll"
    }
    tags = {
      ManagedBy = "Terraform"
      API       = "products"
    }
  }

  # Production API Queue
  "stackfood-sqs-production-queue" = {
    fifo_queue                  = false
    content_based_deduplication = true
    deduplication_scope         = null
    fifo_throughput_limit       = null
    delay_seconds               = 0
    message_retention_seconds   = 1209600
    max_message_size            = 262144
    visibility_timeout_seconds  = 300
    receive_wait_time_seconds   = 5
    sqs_managed_sse_enabled     = true
    create_default_policy       = true

    create_dlq        = true
    dlq_name          = "stackfood-sqs-production-dlq"
    max_receive_count = 5

    dlq_config = {
      delay_seconds              = 0
      max_message_size           = 262144
      message_retention_seconds  = 1209600
      receive_wait_time_seconds  = 0
      visibility_timeout_seconds = 30

      sqs_managed_sse_enabled           = true
      kms_master_key_id                 = null
      kms_data_key_reuse_period_seconds = 300

      content_based_deduplication = false
      deduplication_scope         = null
      fifo_throughput_limit       = null

      redrive_allow_policy = null
      policy               = null

      tags = {
        ManagedBy = "Terraform"
        API       = "production"
      }
    }

    redrive_allow_policy = {
      redrivePermission = "allowAll"
    }
    tags = {
      ManagedBy = "Terraform"
      API       = "production"
    }
  }
}


################
# ECS Clusters #
################

create_ecs_cluster = false

############
### SNS ####
############
sns_topics = {
  # Orders API Topic
  "stackfood-sns-orders-created" = {
    fifo_topic   = false
    display_name = "StackFood Orders Created Events"

    sqs_subscriptions = {
      "stackfood-sqs-orders-created-queue" = {
        raw_message_delivery = false
      }
    }

    tags = {
      ManagedBy = "Terraform"
      API       = "orders"
    }
  }

  # Orders Canceled API Topic
  "stackfood-sns-orders-cancelled" = {
    fifo_topic   = false
    display_name = "StackFood Orders Cancelled Events"

    sqs_subscriptions = {
      "stackfood-sqs-orders-cancelled-queue" = {
        raw_message_delivery = false
      }
    }

    tags = {
      ManagedBy = "Terraform"
      API       = "orders"
    }
  }

  # Order Completed API Topic
  "stackfood-sns-orders-completed-topic" = {
    fifo_topic   = false
    display_name = "StackFood Orders Completed Events"

    sqs_subscriptions = {
      "stackfood-sqs-orders-completed-queue" = {
        raw_message_delivery = false
      }
    }

    tags = {
      ManagedBy = "Terraform"
      API       = "orders"
    }
  }

  # Production API Topic
  "stackfood-sns-production-topic" = {
    fifo_topic   = false
    display_name = "StackFood Production Events"

    sqs_subscriptions = {
      "stackfood-sqs-production-queue" = {
        raw_message_delivery = false
      }
    }

    tags = {
      ManagedBy = "Terraform"
      API       = "production"
    }
  }
}

##################
### DynamoDB ####
##################
dynamodb_tables = {
  "stackfood-orders-prod" = {
    hash_key  = "order_id"
    range_key = "created_at"

    attributes = [
      {
        name = "order_id"
        type = "S"
      },
      {
        name = "created_at"
        type = "N"
      },
      {
        name = "customer_id"
        type = "S"
      },
      {
        name = "status"
        type = "S"
      }
    ]

    # Índices secundários globais
    global_secondary_indexes = [
      {
        name            = "customer-index"
        hash_key        = "customer_id"
        range_key       = "created_at"
        projection_type = "ALL"
      },
      {
        name            = "status-index"
        hash_key        = "status"
        range_key       = "created_at"
        projection_type = "KEYS_ONLY"
      }
    ]

    # Configurações de billing
    billing_mode = "PAY_PER_REQUEST"

    # Habilitar streams para integração com Lambda/processamento de eventos
    stream_enabled   = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    # TTL para expiração automática de pedidos antigos (90 dias)
    ttl_enabled        = true
    ttl_attribute_name = "ttl"

    # Point-in-time recovery para backup
    point_in_time_recovery_enabled = true

    # Criptografia habilitada
    encryption_enabled = true

    # Classe da tabela
    table_class = "STANDARD"
  }

  "stackfood-products-prod" = {
    hash_key = "product_id"

    attributes = [
      {
        name = "product_id"
        type = "S"
      },
      {
        name = "category"
        type = "S"
      },
      {
        name = "name"
        type = "S"
      }
    ]

    # Índice secundário para busca por categoria
    global_secondary_indexes = [
      {
        name            = "category-index"
        hash_key        = "category"
        range_key       = "name"
        projection_type = "ALL"
      }
    ]

    # Pay-per-request para carga variável
    billing_mode = "PAY_PER_REQUEST"

    # Configurações padrão
    stream_enabled                 = false
    ttl_enabled                    = false
    point_in_time_recovery_enabled = true
    encryption_enabled             = true
    table_class                    = "STANDARD"
  }
}
