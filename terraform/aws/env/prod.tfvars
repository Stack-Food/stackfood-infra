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
    name             = "stackfood-auth-validator"
    description      = "Lambda for CPF authentication and JWT validation"
    runtime          = "nodejs18.x"
    handler          = "index.handler"
    filename         = "../lambda-mocks/auth-validator.zip"
    source_code_hash = ""
    memory_size      = 256
    timeout          = 30
    vpc_access       = false # Auth não precisa de VPC
    environment_variables = {
      USER_POOL_ID = "" # Será populado via reference no Terraform
      CLIENT_ID    = "" # Será populado via reference no Terraform
      AWS_REGION   = "us-west-2"
      LOG_LEVEL    = "info"
      NODE_ENV     = "production"
    }
  },
  {
    name             = "stackfood-user-creator"
    description      = "Lambda for creating users in Cognito and application database"
    runtime          = "nodejs18.x"
    handler          = "index.handler"
    filename         = "../lambda-mocks/user-creator.zip"
    source_code_hash = ""
    memory_size      = 256
    timeout          = 30
    vpc_access       = false # User creation não precisa de VPC inicialmente
    environment_variables = {
      USER_POOL_ID = "" # Será populado via reference no Terraform
      CLIENT_ID    = "" # Será populado via reference no Terraform
      AWS_REGION   = "us-west-2"
      LOG_LEVEL    = "info"
      NODE_ENV     = "production"
    }
  },
  {
    name             = "stackfood-prod-api"
    description      = "API for StackFood production application"
    runtime          = "nodejs18.x"
    handler          = "index.handler"
    filename         = "../lambdas/api.zip" # This should point to your lambda code
    source_code_hash = ""                   # Will be computed from the file
    memory_size      = 512
    timeout          = 30
    vpc_access       = true
    environment_variables = {
      DB_HOST   = "stackfood-prod-postgres.internal"
      DB_PORT   = "5432"
      DB_NAME   = "stackfooddb"
      LOG_LEVEL = "info"
      NODE_ENV  = "production"
    }
  },
  {
    name             = "stackfood-prod-worker"
    description      = "Worker for StackFood production application"
    runtime          = "nodejs18.x"
    handler          = "worker.handler"
    filename         = "../lambdas/worker.zip" # This should point to your lambda code
    source_code_hash = ""                      # Will be computed from the file
    memory_size      = 1024
    timeout          = 60
    vpc_access       = true
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

    # API Resources Structure - Incluindo rotas de auth
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

      # API resources (para aplicação no EKS e lambda de criação de usuário)
      "api" = {
        path_part = "api"
      }
      "customers" = {
        path_part = "customers"
        parent_id = null # Will be set to api resource ID
      }
      "customers-cpf" = {
        path_part = "{cpf}"
        parent_id = null # Will be set to customers resource ID
      }
      "order" = {
        path_part = "order"
        parent_id = null # Will be set to api resource ID
      }
      "order-id" = {
        path_part = "{id}"
        parent_id = null # Will be set to order resource ID
      }
      "order-payment" = {
        path_part = "payment"
        parent_id = null # Will be set to order-id resource ID
      }
      "order-change-status" = {
        path_part = "change-status"
        parent_id = null # Will be set to order-id resource ID
      }
      "product" = {
        path_part = "product"
        parent_id = null # Will be set to api resource ID
      }
      "product-all" = {
        path_part = "all"
        parent_id = null # Will be set to product resource ID
      }
      "product-id" = {
        path_part = "{id}"
        parent_id = null # Will be set to product resource ID
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
        resource_key  = "customers"
        http_method   = "POST"
        authorization = "NONE" # Lambda de criação de usuário
      }
      "customers-get-cpf" = {
        resource_key  = "customers-cpf"
        http_method   = "GET"
        authorization = "NONE" # EKS backend (protegido via JWT na aplicação)
        request_parameters = {
          "method.request.path.cpf" = true
        }
      }

      # Order endpoints
      "order-get" = {
        resource_key  = "order"
        http_method   = "GET"
        authorization = "NONE"
      }
      "order-post" = {
        resource_key  = "order"
        http_method   = "POST"
        authorization = "NONE"
      }
      "order-get-id" = {
        resource_key  = "order-id"
        http_method   = "GET"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.id" = true
        }
      }
      "order-payment-put" = {
        resource_key  = "order-payment"
        http_method   = "PUT"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.id" = true
        }
      }
      "order-change-status-put" = {
        resource_key  = "order-change-status"
        http_method   = "PUT"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.id" = true
        }
      }

      # Product endpoints
      "product-all-get" = {
        resource_key  = "product-all"
        http_method   = "GET"
        authorization = "NONE"
      }
      "product-get-id" = {
        resource_key  = "product-id"
        http_method   = "GET"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.id" = true
        }
      }
      "product-delete-id" = {
        resource_key  = "product-id"
        http_method   = "DELETE"
        authorization = "NONE"
        request_parameters = {
          "method.request.path.id" = true
        }
      }
      "product-post" = {
        resource_key  = "product"
        http_method   = "POST"
        authorization = "NONE"
      }
      "product-put" = {
        resource_key  = "product"
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
        resource_key            = "customers"
        integration_http_method = "POST"
        type                    = "AWS_PROXY"
        uri                     = "arn:aws:apigateway:us-west-2:lambda:path/2015-03-31/functions/arn:aws:lambda:us-west-2:ACCOUNT_ID:function:stackfood-user-creator/invocations"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }

      # API integrations (EKS via HTTP proxy - será configurado após deploy do EKS)
      "customers-get-cpf-integration" = {
        method_key              = "customers-get-cpf"
        resource_key            = "customers-cpf"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/customers/{cpf}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.cpf" = "method.request.path.cpf"
        }
      }

      # Order integrations (EKS backend)
      "order-get-integration" = {
        method_key              = "order-get"
        resource_key            = "order"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/order"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "order-post-integration" = {
        method_key              = "order-post"
        resource_key            = "order"
        integration_http_method = "POST"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/order"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "order-get-id-integration" = {
        method_key              = "order-get-id"
        resource_key            = "order-id"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/order/{id}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.id" = "method.request.path.id"
        }
      }
      "order-payment-put-integration" = {
        method_key              = "order-payment-put"
        resource_key            = "order-payment"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/order/{id}/payment"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.id" = "method.request.path.id"
        }
      }
      "order-change-status-put-integration" = {
        method_key              = "order-change-status-put"
        resource_key            = "order-change-status"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/order/{id}/change-status"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.id" = "method.request.path.id"
        }
      }

      # Product integrations (EKS backend)
      "product-all-get-integration" = {
        method_key              = "product-all-get"
        resource_key            = "product-all"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/product/all"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "product-get-id-integration" = {
        method_key              = "product-get-id"
        resource_key            = "product-id"
        integration_http_method = "GET"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/product/{id}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.id" = "method.request.path.id"
        }
      }
      "product-delete-id-integration" = {
        method_key              = "product-delete-id"
        resource_key            = "product-id"
        integration_http_method = "DELETE"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/product/{id}"
        passthrough_behavior    = "WHEN_NO_MATCH"
        request_parameters = {
          "integration.request.path.id" = "method.request.path.id"
        }
      }
      "product-post-integration" = {
        method_key              = "product-post"
        resource_key            = "product"
        integration_http_method = "POST"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/product"
        passthrough_behavior    = "WHEN_NO_MATCH"
      }
      "product-put-integration" = {
        method_key              = "product-put"
        resource_key            = "product"
        integration_http_method = "PUT"
        type                    = "HTTP_PROXY"
        uri                     = "http://stackfood-api-service.default.svc.cluster.local/api/product"
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
        resource_key = "customers"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "order-get-200" = {
        method_key   = "order-get"
        resource_key = "order"
        status_code  = "200"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = true
        }
      }
      "product-all-get-200" = {
        method_key   = "product-all-get"
        resource_key = "product-all"
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
        resource_key        = "customers"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "order-get-200-response" = {
        method_key          = "order-get"
        method_response_key = "order-get-200"
        resource_key        = "order"
        response_parameters = {
          "method.response.header.Access-Control-Allow-Origin" = "'*'"
        }
      }
      "product-all-get-200-response" = {
        method_key          = "product-all-get"
        method_response_key = "product-all-get-200"
        resource_key        = "product-all"
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
    lambda_permissions = {
      "stackfood-auth-validator-permission" = {
        statement_id  = "AllowExecutionFromAPIGateway"
        function_name = "stackfood-auth-validator"
      }
      "stackfood-user-creator-permission" = {
        statement_id  = "AllowExecutionFromAPIGateway"
        function_name = "stackfood-user-creator"
      }
    }
  }
}

##########################
# Cognito Configuration #
##########################
cognito_user_pools = {
  "stackfood-users" = {
    name                     = "stackfood-prod-users"
    alias_attributes         = ["preferred_username"] # CPF será usado via preferred_username
    auto_verified_attributes = []                     # Sem verificação automática (apenas CPF)
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

        read_attributes  = ["preferred_username", "name", "family_name", "custom:cpf"]
        write_attributes = ["name", "family_name", "custom:cpf"]
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

        read_attributes  = ["preferred_username", "name", "family_name", "custom:cpf", "custom:customer_type"]
        write_attributes = ["name", "family_name", "custom:cpf", "custom:customer_type"]
      }
    }

    # Identity Pool para acesso AWS (opcional)
    create_identity_pool             = true
    allow_unauthenticated_identities = false
    default_client_key               = "cpf-auth-app"

    # Custom Attributes para StackFood - Foco em CPF
    schemas = [
      {
        attribute_data_type = "String"
        name                = "preferred_username" # CPF será armazenado aqui
        required            = true
        mutable             = false # CPF não pode ser alterado
        string_attribute_constraints = {
          min_length = "11"
          max_length = "14" # Para CPF com formatação
        }
      },
      {
        attribute_data_type = "String"
        name                = "name"
        required            = true
        mutable             = true
        string_attribute_constraints = {
          min_length = "1"
          max_length = "256"
        }
      },
      {
        attribute_data_type = "String"
        name                = "family_name"
        required            = false
        mutable             = true
        string_attribute_constraints = {
          min_length = "1"
          max_length = "256"
        }
      },
      {
        attribute_data_type      = "String"
        name                     = "custom:cpf"
        required                 = true
        mutable                  = false # CPF não pode ser alterado
        developer_only_attribute = false
        string_attribute_constraints = {
          min_length = "11"
          max_length = "14"
        }
      },
      {
        attribute_data_type      = "String"
        name                     = "custom:customer_type"
        required                 = false
        mutable                  = true
        developer_only_attribute = false
        string_attribute_constraints = {
          min_length = "1"
          max_length = "50"
        }
      },
      {
        attribute_data_type      = "String"
        name                     = "custom:customer_id"
        required                 = false
        mutable                  = false # ID único não pode ser alterado
        developer_only_attribute = false
        string_attribute_constraints = {
          min_length = "1"
          max_length = "100"
        }
      },
      {
        attribute_data_type      = "String"
        name                     = "custom:preferences"
        required                 = false
        mutable                  = true
        developer_only_attribute = false
        string_attribute_constraints = {
          min_length = "1"
          max_length = "2048"
        }
      }
    ]
  }
}
