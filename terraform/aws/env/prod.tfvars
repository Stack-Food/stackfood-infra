aws_region  = "us-west-2"
environment = "prod"

tags = {
  Project    = "StackFood"
  Team       = "DevOps"
  CostCenter = "IT"
}

######################
# VPC Configuration #
######################
vpc_name        = "stackfood-prod-vpc"
vpc_cidr_blocks = ["10.0.0.0/16"]

private_subnets = {
  "private1" = {
    availability_zone = "us-west-2a"
    cidr_block        = "10.0.1.0/24"
  },
  "private2" = {
    availability_zone = "us-west-2b"
    cidr_block        = "10.0.2.0/24"
  },
  "private3" = {
    availability_zone = "us-west-2c"
    cidr_block        = "10.0.3.0/24"
  }
}

public_subnets = {
  "public1" = {
    availability_zone = "us-west-2a"
    cidr_block        = "10.0.101.0/24"
  },
  "public2" = {
    availability_zone = "us-west-2b"
    cidr_block        = "10.0.102.0/24"
  },
  "public3" = {
    availability_zone = "us-west-2c"
    cidr_block        = "10.0.103.0/24"
  }
}

######################
# EKS Configuration #
######################
eks_cluster_name           = "stackfood-prod-eks"
kubernetes_version         = "1.32"
eks_endpoint_public_access = false

eks_node_groups = {
  "api" = {
    desired_size   = 3
    max_size       = 6
    min_size       = 2
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.large"]
    disk_size      = 50
    labels = {
      "role" = "api"
    }
  },
  "worker" = {
    desired_size   = 2
    max_size       = 4
    min_size       = 2
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    instance_types = ["t3.large"]
    disk_size      = 100
    labels = {
      "role" = "worker"
    }
  }
}

######################major_engine_version
# RDS Configuration #
######################
rds_instances = {
  "stackfood-prod-db" = {
    # AWS Academy compliant settings
    allocated_storage            = 20            # Changed from 50 to 20 (within 100GB limit)
    storage_encrypted            = false         # Simplified for AWS Academy
    db_instance_class            = "db.t3.micro" # Changed to supported instance type
    db_username                  = "stackfood"
    manage_master_user_password  = true
    engine                       = "postgres" # Lowercase as required
    engine_version               = "16.3"     # Updated version
    major_engine_version         = "16"
    identifier                   = "stackfood-prod-postgres"
    publicly_accessible          = false
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
eks_cluster_role_name = "c173096a4485959l11267681t1w623941-LabEksClusterRole-PYvjzWerQxXl"
eks_node_role_name    = "c173096a4485959l11267681t1w623941524-LabEksNodeRole-u7CI3SEcaNrk"
rds_role_name         = "LabRole"

######################
# Lambda Configuration #
######################
lambda_functions = [
  {
    name         = "stackfood-auth-validator"
    description  = "Lambda for CPF authentication and JWT validation"
    package_type = "Image"
    image_uri    = "public.ecr.aws/lambda/nodejs:18-latest"
    memory_size  = 256
    timeout      = 30
    vpc_access   = false # Auth não precisa de VPC
    environment_variables = {
      USER_POOL_ID = "" # Será populado via reference no Terraform
      CLIENT_ID    = "" # Será populado via reference no Terraform
      AWS_REGION   = "us-west-2"
      LOG_LEVEL    = "info"
      NODE_ENV     = "production"
    }
  },
  {
    name         = "stackfood-user-creator"
    description  = "Lambda for creating users in Cognito and application database"
    package_type = "Image"
    image_uri    = "public.ecr.aws/lambda/nodejs:18-latest"
    memory_size  = 256
    timeout      = 30
    vpc_access   = false # User creation não precisa de VPC inicialmente
    environment_variables = {
      USER_POOL_ID = "" # Será populado via reference no Terraform
      CLIENT_ID    = "" # Será populado via reference no Terraform
      AWS_REGION   = "us-west-2"
      LOG_LEVEL    = "info"
      NODE_ENV     = "production"
    }
  },
  {
    name         = "stackfood-prod-api"
    description  = "API for StackFood production application"
    package_type = "Image"
    image_uri    = "public.ecr.aws/lambda/nodejs:18-latest"
    memory_size  = 512
    timeout      = 30
    vpc_access   = true
    environment_variables = {
      DB_HOST   = "stackfood-prod-postgres.internal"
      DB_PORT   = "5432"
      DB_NAME   = "stackfooddb"
      LOG_LEVEL = "info"
      NODE_ENV  = "production"
    }
  },
  {
    name         = "stackfood-prod-worker"
    description  = "Worker for StackFood production application"
    package_type = "Image"
    image_uri    = "public.ecr.aws/lambda/nodejs:18-latest"
    memory_size  = 1024
    timeout      = 60
    vpc_access   = true
    environment_variables = {
      DB_HOST            = "stackfood-prod-postgres.internal"
      DB_PORT            = "5432"
      DB_NAME            = "stackfooddb"
      LOG_LEVEL          = "info"
      NODE_ENV           = "production"
      WORKER_CONCURRENCY = "10"
    }
  }
]

##########################
# API Gateway Configuration #
##########################
api_gateways = {
  "stackfood-api" = {
    name                 = "stackfood-prod-api"
    description          = "StackFood Production API Gateway"
    stage_name           = "prod"
    endpoint_type        = "REGIONAL"
    enable_cors          = true
    enable_access_logs   = true
    xray_tracing_enabled = false

    # CORS Configuration simples
    cors_allow_origins     = ["*"]
    cors_allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    cors_allow_headers     = ["Content-Type", "X-Amz-Date", "Authorization", "X-Api-Key"]
    cors_allow_credentials = false

    # Sem throttling para POC
    cache_cluster_enabled = false

    # API Resources Structure - Reorganizada para evitar conflitos
    resources = {
      # Auth resources (para lambdas de autenticação)
      "auth" = {
        path_part = "auth"
      }
      "auth-cpf" = {
        path_part = "cpf"
        parent_id = null # Will be set to auth resource ID
      }
      "auth-validate" = {
        path_part = "validate"
        parent_id = null # Will be set to auth resource ID
      }

      # API resources - estrutura reorganizada
      "api" = {
        path_part = "api"
      }

      # Customers - com estrutura própria
      "api-customers" = {
        path_part = "customers"
        parent_id = null # Will be set to api resource ID
      }
      "api-customers-cpf" = {
        path_part = "{cpf}"
        parent_id = null # Will be set to api-customers resource ID
      }

      # Orders - com estrutura própria
      "api-orders" = {
        path_part = "orders"
        parent_id = null # Will be set to api resource ID
      }
      "api-orders-id" = {
        path_part = "{orderId}"
        parent_id = null # Will be set to api-orders resource ID
      }
      "api-orders-id-payment" = {
        path_part = "payment"
        parent_id = null # Will be set to api-orders-id resource ID
      }
      "api-orders-id-status" = {
        path_part = "change-status"
        parent_id = null # Will be set to api-orders-id resource ID
      }

      # Products - com estrutura própria
      "api-products" = {
        path_part = "products"
        parent_id = null # Will be set to api resource ID
      }
      "api-products-all" = {
        path_part = "all"
        parent_id = null # Will be set to api-products resource ID
      }
      "api-products-id" = {
        path_part = "{productId}"
        parent_id = null # Will be set to api-products resource ID
      }
    }

    # API Methods - Incluindo auth e rotas do Swagger
    methods = {
      # Auth endpoints (para lambdas de autenticação)
      "auth-cpf-post" = {
        resource_key  = "auth-cpf"
        http_method   = "POST"
        authorization = "NONE"
      }
      "auth-validate-post" = {
        resource_key  = "auth-validate"
        http_method   = "POST"
        authorization = "NONE"
      }

      # Customers endpoints
      "customers-post" = {
        resource_key  = "api-customers"
        http_method   = "POST"
        authorization = "NONE" # Lambda de criação de usuário
      }
      "customers-get-cpf" = {
        resource_key  = "api-customers-cpf"
        http_method   = "GET"
        authorization = "NONE" # EKS backend (protegido via JWT na aplicação)
        request_parameters = {
          "method.request.path.cpf" = true
        }
      }

      # Order endpoints
      "orders-get" = {
        resource_key  = "api-orders"
        http_method   = "GET"
        authorization = "NONE"
      }
      "orders-post" = {
        resource_key  = "api-orders"
        http_method   = "POST"
        authorization = "NONE"
      }
      "orders-get-id" = {
        resource_key  = "api-orders-id"
        http_method   = "GET"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.orderId" = true
        }
      }
      "orders-payment-put" = {
        resource_key  = "api-orders-id-payment"
        http_method   = "PUT"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.orderId" = true
        }
      }
      "orders-status-put" = {
        resource_key  = "api-orders-id-status"
        http_method   = "PUT"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.orderId" = true
        }
      }

      # Product endpoints
      "products-all-get" = {
        resource_key  = "api-products-all"
        http_method   = "GET"
        authorization = "NONE"
      }
      "products-get-id" = {
        resource_key  = "api-products-id"
        http_method   = "GET"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.productId" = true
        }
      }
      "products-delete-id" = {
        resource_key  = "api-products-id"
        http_method   = "DELETE"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.productId" = true
        }
      }
      "products-post" = {
        resource_key  = "api-products"
        http_method   = "POST"
        authorization = "NONE"
      }
      "products-put" = {
        resource_key  = "api-products"
        http_method   = "PUT"
        authorization = "NONE"
      }
    }

    # Integrações com roteamento inteligente: Auth → Lambda, API → EKS/Lambda
    integrations = {
      # Auth integrations (para lambdas de autenticação)
      "auth-cpf-post-integration" = {
        method_key              = "auth-cpf-post"
        resource_key            = "auth-cpf"
        integration_http_method = "POST"
        type                    = "AWS_PROXY"
        uri                     = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:ACCOUNT_ID:function:stackfood-auth-validator/invocations"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "auth-validate-post-integration" = {
        method_key              = "auth-validate-post"
        resource_key            = "auth-validate"
        integration_http_method = "POST"
        type                    = "AWS_PROXY"
        uri                     = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:ACCOUNT_ID:function:stackfood-auth-validator/invocations"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }

      # Customer creation integration (Lambda para criação de usuário)
      "customers-post-integration" = {
        method_key              = "customers-post"
        resource_key            = "api-customers"
        integration_http_method = "POST"
        type                    = "AWS_PROXY"
        uri                     = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:ACCOUNT_ID:function:stackfood-user-creator/invocations"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }

      # API integrations (EKS via HTTP proxy - será configurado após deploy do EKS)
      "customers-get-cpf-integration" = {
        method_key              = "customers-get-cpf"
        resource_key            = "api-customers-cpf"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/customers/{cpf}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.cpf" = "method.request.path.cpf"
        }
      }

      # Order integrations (EKS backend)
      "orders-get-integration" = {
        method_key              = "orders-get"
        resource_key            = "api-orders"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/orders"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "orders-post-integration" = {
        method_key              = "orders-post"
        resource_key            = "api-orders"
        integration_http_method = "POST"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/orders"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "orders-get-id-integration" = {
        method_key              = "orders-get-id"
        resource_key            = "api-orders-id"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/orders/{orderId}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.orderId" = "method.request.path.orderId"
        }
      }
      "orders-payment-put-integration" = {
        method_key              = "orders-payment-put"
        resource_key            = "api-orders-id-payment"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/orders/{orderId}/payment"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.orderId" = "method.request.path.orderId"
        }
      }
      "orders-status-put-integration" = {
        method_key              = "orders-status-put"
        resource_key            = "api-orders-id-status"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/orders/{orderId}/change-status"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.orderId" = "method.request.path.orderId"
        }
      }

      # Product integrations (EKS backend)
      "products-all-get-integration" = {
        method_key              = "products-all-get"
        resource_key            = "api-products-all"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/products/all"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "products-get-id-integration" = {
        method_key              = "products-get-id"
        resource_key            = "api-products-id"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/products/{productId}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.productId" = "method.request.path.productId"
        }
      }
      "products-delete-id-integration" = {
        method_key              = "products-delete-id"
        resource_key            = "api-products-id"
        integration_http_method = "DELETE"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/products/{productId}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.productId" = "method.request.path.productId"
        }
      }
      "products-post-integration" = {
        method_key              = "products-post"
        resource_key            = "api-products"
        integration_http_method = "POST"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/products"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "products-put-integration" = {
        method_key              = "products-put"
        resource_key            = "api-products"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/products"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
    }

    # Method Responses - Incluindo auth endpoints
    method_responses = {
      # Auth responses
      "auth-cpf-post-200" = {
        method_key   = "auth-cpf-post"
        resource_key = "auth-cpf"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "auth-validate-post-200" = {
        method_key   = "auth-validate-post"
        resource_key = "auth-validate"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }

      # API responses
      "customers-post-200" = {
        method_key   = "customers-post"
        resource_key = "api-customers"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "customers-get-cpf-200" = {
        method_key   = "customers-get-cpf"
        resource_key = "api-customers-cpf"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "orders-get-200" = {
        method_key   = "orders-get"
        resource_key = "api-orders"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "orders-post-200" = {
        method_key   = "orders-post"
        resource_key = "api-orders"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "orders-get-id-200" = {
        method_key   = "orders-get-id"
        resource_key = "api-orders-id"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "products-all-get-200" = {
        method_key   = "products-all-get"
        resource_key = "api-products-all"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "products-get-id-200" = {
        method_key   = "products-get-id"
        resource_key = "api-products-id"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
    }

    # Integration Responses - Incluindo auth endpoints
    integration_responses = {
      # Auth responses
      "auth-cpf-post-200-response" = {
        method_key          = "auth-cpf-post"
        method_response_key = "auth-cpf-post-200"
        resource_key        = "auth-cpf"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "auth-validate-post-200-response" = {
        method_key          = "auth-validate-post"
        method_response_key = "auth-validate-post-200"
        resource_key        = "auth-validate"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }

      # API responses
      "customers-post-200-response" = {
        method_key          = "customers-post"
        method_response_key = "customers-post-200"
        resource_key        = "api-customers"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "customers-get-cpf-200-response" = {
        method_key          = "customers-get-cpf"
        method_response_key = "customers-get-cpf-200"
        resource_key        = "api-customers-cpf"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "orders-get-200-response" = {
        method_key          = "orders-get"
        method_response_key = "orders-get-200"
        resource_key        = "api-orders"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "orders-post-200-response" = {
        method_key          = "orders-post"
        method_response_key = "orders-post-200"
        resource_key        = "api-orders"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "orders-get-id-200-response" = {
        method_key          = "orders-get-id"
        method_response_key = "orders-get-id-200"
        resource_key        = "api-orders-id"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "products-all-get-200-response" = {
        method_key          = "products-all-get"
        method_response_key = "products-all-get-200"
        resource_key        = "api-products-all"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "products-get-id-200-response" = {
        method_key          = "products-get-id"
        method_response_key = "products-get-id-200"
        resource_key        = "api-products-id"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
    }

    # Sem API Keys para POC
    api_keys = {}

    # Sem Usage Plans para POC
    usage_plans = {}

    # Sem Usage Plan Keys para POC
    usage_plan_keys = {}

    # Lambda Permissions para as funções de auth e user creation
    # Removidas temporariamente para evitar dependência circular
    # As permissões serão adicionadas manualmente após deploy das Lambda functions
    lambda_permissions = {}
  }
}

##########################
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
