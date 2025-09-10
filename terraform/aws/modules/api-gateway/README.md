# API Gateway Terraform Module

Este módulo cria um API Gateway REST na AWS com suporte completo para integração com Lambda functions, recursos hierárquicos, autenticação, throttling, caching e monitoramento.

## Características

- ✅ **API Gateway REST API** com configuração completa
- ✅ **Recursos hierárquicos** com suporte a path parameters
- ✅ **Métodos HTTP** com diferentes tipos de autorização
- ✅ **Integração Lambda** com AWS_PROXY
- ✅ **CORS** configurável
- ✅ **API Keys** e Usage Plans
- ✅ **Throttling** e Rate Limiting
- ✅ **Caching** configurável
- ✅ **CloudWatch Logs** e X-Ray tracing
- ✅ **Lambda Permissions** automáticas
- ✅ **Deployment** e Stage management

## Estrutura de Arquivos

```
api-gateway/
├── main.tf          # Recursos principais do API Gateway
├── variables.tf     # Variáveis de entrada
├── output.tf        # Saídas do módulo
└── README.md        # Esta documentação
```

## Uso Básico

```hcl
module "api_gateway" {
  source = "../modules/api-gateway/"

  # Configurações básicas
  api_name    = "my-api"
  description = "API para minha aplicação"
  environment = "prod"
  stage_name  = "v1"

  # CORS
  enable_cors = true

  # Recursos da API
  resources = {
    "users" = {
      path_part = "users"
    }
    "user-id" = {
      path_part = "{id}"
      parent_id = null # Será definido programaticamente
    }
  }

  # Métodos
  methods = {
    "users-get" = {
      resource_key  = "users"
      http_method   = "GET"
      authorization = "NONE"
    }
    "user-get" = {
      resource_key  = "user-id"
      http_method   = "GET"
      authorization = "AWS_IAM"
      request_parameters = {
        "method.request.path.id" = true
      }
    }
  }

  # Integrações Lambda
  integrations = {
    "users-integration" = {
      method_key              = "users-get"
      resource_key            = "users"
      integration_http_method = "POST"
      type                   = "AWS_PROXY"
      uri                    = "arn:aws:apigateway:region:lambda:path/2015-03-31/functions/function-arn/invocations"
    }
  }
}
```

## Uso Avançado

### 1. API Completa com Autenticação

```hcl
module "api_gateway" {
  source = "../modules/api-gateway/"

  api_name    = "stackfood-api"
  description = "StackFood API Gateway"
  environment = "prod"
  stage_name  = "v1"

  # CORS configurado
  enable_cors            = true
  cors_allow_origins     = ["https://myapp.com"]
  cors_allow_credentials = true

  # Throttling
  throttle_settings = {
    rate_limit  = 10000
    burst_limit = 5000
  }

  # Cache habilitado
  cache_cluster_enabled = true
  cache_cluster_size    = "1.6"

  # Monitoramento
  enable_access_logs   = true
  xray_tracing_enabled = true

  # API Keys
  api_keys = {
    "mobile-app" = {
      name        = "mobile-app-key"
      description = "Chave para app mobile"
      enabled     = true
    }
  }

  # Usage Plans
  usage_plans = {
    "premium" = {
      name        = "Premium Plan"
      description = "Plano premium com limites maiores"
      quota_settings = {
        limit  = 50000
        period = "DAY"
      }
      throttle_settings = {
        rate_limit  = 10000
        burst_limit = 5000
      }
    }
  }

  # Associar API Key com Usage Plan
  usage_plan_keys = {
    "mobile-premium" = {
      api_key    = "mobile-app"
      usage_plan = "premium"
    }
  }
}
```

### 2. Integração com Lambda

```hcl
# Primeiro crie as Lambda functions
module "lambda_auth" {
  source = "../modules/lambda/"

  function_name = "auth-function"
  handler      = "index.handler"
  runtime      = "nodejs18.x"
  # ... outras configurações
}

# Depois configure o API Gateway
module "api_gateway" {
  source = "../modules/api-gateway/"

  # ... configurações básicas

  integrations = {
    "auth-integration" = {
      method_key              = "auth-post"
      resource_key            = "auth"
      integration_http_method = "POST"
      type                   = "AWS_PROXY"
      uri                    = module.lambda_auth.function_invoke_arn
    }
  }

  # Permissões Lambda
  lambda_permissions = {
    "auth-permission" = {
      statement_id  = "AllowAPIGateway"
      function_name = module.lambda_auth.function_name
    }
  }
}
```

## Variáveis de Entrada

### Obrigatórias

| Nome          | Tipo     | Descrição                        |
| ------------- | -------- | -------------------------------- |
| `api_name`    | `string` | Nome do API Gateway              |
| `environment` | `string` | Environment (dev, staging, prod) |
| `stage_name`  | `string` | Nome do stage de deployment      |

### Opcionais

| Nome                    | Tipo     | Default      | Descrição                                  |
| ----------------------- | -------- | ------------ | ------------------------------------------ |
| `description`           | `string` | `""`         | Descrição do API Gateway                   |
| `endpoint_type`         | `string` | `"REGIONAL"` | Tipo de endpoint (EDGE, REGIONAL, PRIVATE) |
| `enable_cors`           | `bool`   | `false`      | Habilitar CORS                             |
| `enable_access_logs`    | `bool`   | `true`       | Habilitar logs de acesso                   |
| `xray_tracing_enabled`  | `bool`   | `false`      | Habilitar X-Ray tracing                    |
| `cache_cluster_enabled` | `bool`   | `false`      | Habilitar cache                            |
| `throttle_settings`     | `object` | `null`       | Configurações de throttling                |

### Estruturas Complexas

#### Resources

```hcl
resources = {
  "resource-name" = {
    path_part = "path"          # Parte do path (ex: "users", "{id}")
    parent_id = "parent-id"     # ID do recurso pai (opcional)
  }
}
```

#### Methods

```hcl
methods = {
  "method-name" = {
    resource_key         = "resource-name"     # Chave do recurso
    http_method          = "GET"              # Método HTTP
    authorization        = "NONE"             # Tipo de autorização
    api_key_required     = false              # Requer API key
    request_parameters   = {}                 # Parâmetros da requisição
  }
}
```

#### Integrations

```hcl
integrations = {
  "integration-name" = {
    method_key              = "method-name"          # Chave do método
    resource_key            = "resource-name"        # Chave do recurso
    integration_http_method = "POST"                 # Método de integração
    type                   = "AWS_PROXY"             # Tipo de integração
    uri                    = "lambda-arn"            # URI da integração
    timeout_milliseconds   = 29000                   # Timeout
  }
}
```

## Saídas

| Nome               | Descrição                              |
| ------------------ | -------------------------------------- |
| `api_id`           | ID do API Gateway                      |
| `api_arn`          | ARN do API Gateway                     |
| `api_endpoint`     | URL completa do endpoint               |
| `stage_invoke_url` | URL de invocação do stage              |
| `execution_arn`    | ARN de execução para permissões Lambda |
| `api_key_values`   | Valores das API keys (sensível)        |
| `api_summary`      | Resumo da API criada                   |

## Exemplos de Estruturas de API

### 1. API Simples (Health Check)

```hcl
resources = {
  "health" = {
    path_part = "health"
  }
}

methods = {
  "health-get" = {
    resource_key  = "health"
    http_method   = "GET"
    authorization = "NONE"
  }
}

integrations = {
  "health-mock" = {
    method_key              = "health-get"
    resource_key            = "health"
    integration_http_method = "GET"
    type                   = "MOCK"
    uri                    = ""
    request_templates = {
      "application/json" = "{\"statusCode\": 200}"
    }
  }
}
```

### 2. API RESTful Completa

```hcl
resources = {
  "users" = {
    path_part = "users"
  }
  "user-id" = {
    path_part = "{id}"
    parent_id = null  # Será users resource ID
  }
  "orders" = {
    path_part = "orders"
  }
  "order-id" = {
    path_part = "{id}"
    parent_id = null  # Será orders resource ID
  }
}

methods = {
  # Users CRUD
  "users-get"    = { resource_key = "users",   http_method = "GET",    authorization = "AWS_IAM" }
  "users-post"   = { resource_key = "users",   http_method = "POST",   authorization = "AWS_IAM" }
  "user-get"     = { resource_key = "user-id", http_method = "GET",    authorization = "AWS_IAM" }
  "user-put"     = { resource_key = "user-id", http_method = "PUT",    authorization = "AWS_IAM" }
  "user-delete"  = { resource_key = "user-id", http_method = "DELETE", authorization = "AWS_IAM" }

  # Orders CRUD
  "orders-get"   = { resource_key = "orders",   http_method = "GET",  authorization = "AWS_IAM" }
  "orders-post"  = { resource_key = "orders",   http_method = "POST", authorization = "AWS_IAM" }
  "order-get"    = { resource_key = "order-id", http_method = "GET",  authorization = "AWS_IAM" }
}
```

## Tipos de Autorização Suportados

- `NONE` - Sem autorização
- `AWS_IAM` - Autorização via IAM
- `CUSTOM` - Authorizer personalizado
- `COGNITO_USER_POOLS` - Cognito User Pools

## Tipos de Integração Suportados

- `AWS_PROXY` - Integração proxy com AWS Lambda
- `AWS` - Integração direta com serviços AWS
- `HTTP_PROXY` - Proxy HTTP
- `HTTP` - Integração HTTP personalizada
- `MOCK` - Resposta mock

## Monitoramento e Logs

O módulo automaticamente configura:

- **CloudWatch Logs** para requests do API Gateway
- **X-Ray Tracing** (quando habilitado)
- **CloudWatch Metrics** padrão do API Gateway
- **Access Logs** personalizáveis

## Segurança

### CORS

```hcl
enable_cors            = true
cors_allow_origins     = ["https://myapp.com"]
cors_allow_methods     = ["GET", "POST", "PUT", "DELETE"]
cors_allow_headers     = ["Content-Type", "Authorization"]
cors_allow_credentials = true
```

### API Keys e Usage Plans

```hcl
api_keys = {
  "app-key" = {
    name    = "my-app-key"
    enabled = true
  }
}

usage_plans = {
  "basic" = {
    name = "Basic Plan"
    quota_settings = {
      limit  = 10000
      period = "DAY"
    }
    throttle_settings = {
      rate_limit  = 1000
      burst_limit = 500
    }
  }
}
```

### Throttling

```hcl
throttle_settings = {
  rate_limit  = 10000  # Requisições por segundo
  burst_limit = 5000   # Burst máximo
}
```

## Troubleshooting

### Problemas Comuns

1. **Erro de permissão Lambda**: Verifique se `lambda_permissions` está configurado
2. **CORS não funciona**: Verifique se métodos OPTIONS estão configurados
3. **502 Bad Gateway**: Verifique a integração Lambda e formato de resposta
4. **Rate Limiting**: Verifique configurações de usage plans e throttling

### Logs e Debug

```bash
# Ver logs do API Gateway
aws logs describe-log-groups --log-group-name-prefix "API-Gateway-Execution-Logs"

# Ver métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=my-api
```

## Migração e Updates

Para atualizar uma API existente:

1. Modifique as configurações no Terraform
2. Execute `terraform plan` para revisar mudanças
3. Execute `terraform apply`
4. O módulo automaticamente fará redeploy quando necessário

## Contribuição

Para contribuir com este módulo:

1. Siga o padrão de nomenclatura existente
2. Adicione validações para novas variáveis
3. Documente novas funcionalidades
4. Teste com diferentes cenários

## License

Este módulo está sob a licença MIT.
