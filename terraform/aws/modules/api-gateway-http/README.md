# API Gateway HTTP Module

Este módulo cria um API Gateway HTTP (v2) com integração híbrida para:

- **VPC Link**: Roteamento de tráfego para microserviços no EKS via NLB (NGINX Ingress)
- **Lambda**: Integração direta com função Lambda para autenticação e gestão de clientes

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                  API Gateway HTTP (v2)                           │
│  https://api-id.execute-api.region.amazonaws.com                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Routes                                                     │ │
│  │                                                             │ │
│  │  POST /auth      ──────────┐                               │ │
│  │  POST /customer  ──────────┼─► Lambda Integration          │ │
│  │                            │   (stackfood-auth)             │ │
│  │                            │                                │ │
│  │  $default (/*) ────────────┼─► VPC Link ──► NLB ──► EKS    │ │
│  │                            │   (microservices)              │ │
│  └────────────────────────────┴───────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘

┌─────────────┐      ┌──────────────┐      ┌───────────────────┐
│   Lambda    │      │   VPC Link   │      │  NGINX Ingress    │
│ stackfood-  │      │              │      │  (NLB) in EKS     │
│    auth     │      │  ┌────────┐  │      │                   │
│             │      │  │Security│  │      │  ┌──────────────┐ │
│  - /auth    │      │  │ Group  │  │      │  │ Microservices│ │
│  - /customer│      │  └────────┘  │      │  │              │ │
└─────────────┘      └──────────────┘      │  │ - customers  │ │
                                            │  │ - products   │ │
                                            │  │ - orders     │ │
                                            │  │ - payments   │ │
                                            │  │ - production │ │
                                            │  └──────────────┘ │
                                            └───────────────────┘
```

## Características

### API Gateway HTTP v2

- **Protocolo**: HTTP/HTTPS
- **Performance**: Menor latência e custo que REST API
- **Auto-deploy**: Stage `$default` com deploy automático
- **Roteamento**: Baseado em path e método HTTP

### Integração VPC Link

- **Rota**: `$default` (catch-all para tráfego não mapeado)
- **Destino**: Network Load Balancer do NGINX Ingress
- **Método**: HTTP_PROXY (passa requisição completa)
- **Timeout**: 30 segundos
- **Subnets**: Privadas do VPC

### Integração Lambda

- **Rotas**:
  - `POST /auth` - Autenticação CPF/JWT
  - `POST /customer` - Criação de clientes
- **Tipo**: AWS_PROXY (integração nativa)
- **Payload Format**: 2.0 (otimizado para HTTP API)
- **Timeout**: 30 segundos
- **Permissions**: Automáticas via Lambda Permission

## Uso

### Configuração Básica

```hcl
module "stackfood_http_api" {
  source = "../modules/api-gateway-http/"

  name       = "stackfood-http-api"
  depends_on = [module.eks, module.nginx-ingress, module.lambda]

  # VPC Configuration
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  private_subnet_ids         = module.vpc.private_subnet_ids
  cluster_security_group_ids = module.eks.cluster_security_group_id

  # NLB Integration (VPC Link)
  nlb_listener_arn = module.nginx-ingress.load_balancer-arn
  lb_arn           = module.nginx-ingress.load_balancer-arn

  # Lambda Integration
  enable_lambda_integration = true
  lambda_invoke_arn         = module.lambda["stackfood-auth"].function_invoke_arn
  lambda_function_name      = module.lambda["stackfood-auth"].function_name

  tags = var.tags
}
```

### Variáveis

| Nome                         | Descrição                | Tipo           | Default | Obrigatório   |
| ---------------------------- | ------------------------ | -------------- | ------- | ------------- |
| `name`                       | Nome da API Gateway      | `string`       | -       | ✅            |
| `vpc_id`                     | ID da VPC                | `string`       | -       | ✅            |
| `private_subnet_ids`         | IDs das subnets privadas | `list(string)` | -       | ✅            |
| `public_subnet_ids`          | IDs das subnets públicas | `list(string)` | -       | ✅            |
| `cluster_security_group_ids` | Security Group do EKS    | `string`       | -       | ✅            |
| `nlb_listener_arn`           | ARN do listener do NLB   | `string`       | -       | ✅            |
| `lb_arn`                     | ARN do Load Balancer     | `string`       | -       | ✅            |
| `enable_lambda_integration`  | Habilitar rotas Lambda   | `bool`         | `false` | ❌            |
| `lambda_invoke_arn`          | ARN de invoke da Lambda  | `string`       | `""`    | Condicional\* |
| `lambda_function_name`       | Nome da função Lambda    | `string`       | `""`    | Condicional\* |
| `tags`                       | Tags para recursos       | `map(string)`  | `{}`    | ❌            |

\*Obrigatório se `enable_lambda_integration = true`

### Outputs

| Nome                         | Descrição                            |
| ---------------------------- | ------------------------------------ |
| `api_id`                     | ID da API Gateway HTTP               |
| `invoke_url`                 | URL base para invocar a API          |
| `execution_arn`              | ARN de execução (para permissions)   |
| `vpc_link_id`                | ID do VPC Link criado                |
| `lambda_integration_enabled` | Status da integração Lambda          |
| `auth_route_id`              | ID da rota /auth (se habilitada)     |
| `customer_route_id`          | ID da rota /customer (se habilitada) |

## Rotas Disponíveis

### Rotas Lambda (quando `enable_lambda_integration = true`)

#### POST /auth

Autenticação de usuário com CPF e retorno de token JWT.

**Request:**

```bash
POST https://api-id.execute-api.us-east-1.amazonaws.com/auth
Content-Type: application/json

{
  "cpf": "12345678900"
}
```

**Response:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

#### POST /customer

Criação de novo cliente no sistema.

**Request:**

```bash
POST https://api-id.execute-api.us-east-1.amazonaws.com/customer
Content-Type: application/json

{
  "cpf": "12345678900",
  "name": "João Silva",
  "email": "joao@example.com"
}
```

**Response:**

```json
{
  "customerId": "uuid-here",
  "cpf": "12345678900",
  "name": "João Silva",
  "email": "joao@example.com"
}
```

### Rotas VPC Link (default)

Todas as outras rotas são automaticamente encaminhadas para os microserviços via NLB:

```bash
# Customers Service
GET/POST/PUT/DELETE https://api-id.execute-api.us-east-1.amazonaws.com/customers/*

# Products Service
GET/POST/PUT/DELETE https://api-id.execute-api.us-east-1.amazonaws.com/products/*

# Orders Service
GET/POST/PUT/DELETE https://api-id.execute-api.us-east-1.amazonaws.com/orders/*

# Payments Service
GET/POST/PUT/DELETE https://api-id.execute-api.us-east-1.amazonaws.com/payments/*

# Production Service
GET/POST/PUT/DELETE https://api-id.execute-api.us-east-1.amazonaws.com/production/*
```

## Recursos Criados

1. **aws_apigatewayv2_api**: API Gateway HTTP principal
2. **aws_apigatewayv2_vpc_link**: VPC Link para conexão com NLB
3. **aws_apigatewayv2_integration** (VPC): Integração HTTP_PROXY com NLB
4. **aws_apigatewayv2_route** (default): Rota catch-all para VPC Link
5. **aws_apigatewayv2_stage**: Stage `$default` com auto-deploy
6. **aws_security_group**: Security Group para VPC Link

### Recursos Lambda (condicionais)

7. **aws_apigatewayv2_integration** (auth_lambda): Integração AWS_PROXY
8. **aws_apigatewayv2_integration** (customer_lambda): Integração AWS_PROXY
9. **aws_apigatewayv2_route** (POST /auth): Rota para autenticação
10. **aws_apigatewayv2_route** (POST /customer): Rota para clientes
11. **aws_lambda_permission** (auth): Permissão de invocação
12. **aws_lambda_permission** (customer): Permissão de invocação

## Fluxo de Requisições

### Requisição para Lambda (/auth ou /customer)

```
Cliente → API Gateway → Lambda → Resposta
   ↓         ↓           ↓
 HTTP     Validação   Processa
Request   de rota    e retorna
```

### Requisição para Microserviços (outras rotas)

```
Cliente → API Gateway → VPC Link → NLB → NGINX Ingress → Microserviço
   ↓         ↓            ↓        ↓         ↓              ↓
 HTTP     Match        Private  Load    Roteamento      Processa
Request   $default     Subnet   Balance   por path      e retorna
```

## Segurança

### VPC Link Security Group

- **Egress**: Permite todo tráfego de saída (0.0.0.0/0)
- **Ingress**: Controlado pelo Security Group do EKS

### Lambda Permissions

- **Principal**: apigateway.amazonaws.com
- **Source ARN**: Específico para cada rota (/auth, /customer)
- **Action**: lambda:InvokeFunction

## Monitoramento

### CloudWatch Logs

API Gateway HTTP cria automaticamente logs em:

```
/aws/apigateway/<api-id>/<stage-name>
```

### Métricas CloudWatch

- `Count`: Número de requisições
- `IntegrationLatency`: Latência backend
- `Latency`: Latência total
- `4XXError`: Erros do cliente
- `5XXError`: Erros do servidor

## Custos

API Gateway HTTP v2 é cobrado por:

- **Milhão de requisições**: ~$1.00
- **Transferência de dados**: Variável por região

Benefícios vs REST API:

- ⬇️ 70% mais barato
- ⚡ Menor latência
- 🚀 Auto-deploy

## Limitações

### AWS Academy

- ✅ VPC Link: Suportado
- ✅ Lambda Integration: Suportado
- ✅ HTTP API: Suportado
- ❌ Custom Domain: Requer certificado ACM
- ❌ WAF: Não disponível

### API Gateway HTTP

- Não suporta API Keys (use Cognito ou Lambda Authorizers)
- Não suporta Usage Plans
- Payload máximo: 10 MB

## Troubleshooting

### VPC Link em estado FAILED

```bash
# Verificar Security Groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Verificar subnets privadas
aws ec2 describe-subnets --subnet-ids <subnet-ids>
```

### Lambda não é invocada

```bash
# Verificar permissões
aws lambda get-policy --function-name stackfood-auth

# Testar Lambda diretamente
aws lambda invoke --function-name stackfood-auth \
  --payload '{"cpf":"12345678900"}' response.json
```

### Erro 500 em rotas de microserviços

```bash
# Verificar NLB targets
aws elbv2 describe-target-health \
  --target-group-arn <tg-arn>

# Verificar NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx <nginx-pod>
```

### Testar rotas localmente

```bash
# Teste Lambda route
curl -X POST https://<api-id>.execute-api.us-east-1.amazonaws.com/auth \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}'

# Teste VPC Link route
curl https://<api-id>.execute-api.us-east-1.amazonaws.com/customers
```

## Migração de REST API

Se você está migrando do módulo `api-gateway` (REST API) para este módulo (HTTP API):

### Diferenças Principais

| Característica | REST API | HTTP API |
| -------------- | -------- | -------- |
| Custo          | $$$      | $        |
| Latência       | ~100ms   | ~50ms    |
| Deployment     | Manual   | Auto     |
| Payload Format | 1.0      | 2.0      |
| API Type       | v1       | v2       |

### Checklist de Migração

- [ ] Atualizar Lambda payload format de 1.0 para 2.0
- [ ] Revisar estrutura de resposta da Lambda
- [ ] Testar rotas Lambda (/auth, /customer)
- [ ] Validar VPC Link com microserviços
- [ ] Atualizar URLs nos clientes
- [ ] Configurar monitoramento CloudWatch

## Exemplos de Uso

### Habilitar apenas VPC Link (sem Lambda)

```hcl
module "api_gateway_http" {
  source = "../modules/api-gateway-http/"

  name                       = "my-api"
  enable_lambda_integration  = false  # Desabilitar Lambda

  # Apenas configuração VPC
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  # ... resto da config
}
```

### Configuração Completa (Lambda + VPC Link)

```hcl
module "api_gateway_http" {
  source = "../modules/api-gateway-http/"

  name                      = "stackfood-api"
  enable_lambda_integration = true

  # Lambda
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name

  # VPC Link
  nlb_listener_arn           = module.nlb.listener_arn
  lb_arn                     = module.nlb.arn
  cluster_security_group_ids = module.eks.security_group_id

  # Network
  vpc_id             = module.vpc.id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  tags = {
    Environment = "production"
    Project     = "stackfood"
  }
}
```

## Referências

- [API Gateway HTTP API Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html)
- [VPC Links for HTTP APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vpc-links.html)
- [Lambda Integrations](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html)
- [Payload Format Version 2.0](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html#http-api-develop-integrations-lambda.proxy-format)

## Contribuição

Para adicionar novas rotas Lambda:

1. Criar integração `aws_apigatewayv2_integration`
2. Criar rota `aws_apigatewayv2_route` com route_key específico
3. Adicionar permissão `aws_lambda_permission`
4. Atualizar documentação

Para modificar VPC Link:

1. Ajustar security group rules se necessário
2. Revisar subnets para alta disponibilidade
3. Considerar timeout para operações longas
