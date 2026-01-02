# API Gateway Module - StackFood

Módulo Terraform para criar AWS API Gateway com roteamento híbrido: Lambda (auth) + VPC Link para microserviços no EKS.

---

## 🎯 Arquitetura

```
Internet
    ↓
AWS API Gateway (Regional)
    ├── /auth → Lambda (stackfood-auth)
    ├── /customer → Lambda (stackfood-auth)
    └── /microservices/* → VPC Link
                              ↓
                        Network Load Balancer (NLB)
                              ↓
                        NGINX Ingress Controller
                              ↓
                        Kubernetes Services (EKS)
                              ├── stackfood-customers:8084
                              ├── stackfood-products:8080
                              ├── stackfood-orders:8081
                              ├── stackfood-payments:8082
                              └── stackfood-production:8083
```

---

## 📋 Recursos Criados

### 1. API Gateway REST API
- **Type**: Regional API
- **Protocol**: HTTP/HTTPS
- **Custom Domain**: Opcional (ACM certificate)

### 2. Lambda Integration (Auth)
- **Routes**:
  - `POST /auth` - Autenticação via Cognito
  - `POST /customer` - Criação de customer
- **Integration**: AWS_PROXY (Lambda function)

### 3. VPC Link
- **Purpose**: Conectar API Gateway ao EKS cluster
- **Target**: Network Load Balancer (NGINX Ingress)
- **Connection**: Private (VPC)

### 4. Microservices Routes (HTTP_PROXY via VPC Link)

| Route | Microserviço | K8s Service | Port | Namespace |
|-------|--------------|-------------|------|-----------|
| `/customers/{proxy+}` | Customers | stackfood-customers | 8084 | customers |
| `/products/{proxy+}` | Products | stackfood-products | 8080 | products |
| `/orders/{proxy+}` | Orders | stackfood-orders | 8081 | orders |
| `/payments/{proxy+}` | Payments | stackfood-payments | 8082 | payments |
| `/production/{proxy+}` | Production | stackfood-production | 8083 | production |

---

## 🚀 Uso

### Exemplo de Configuração

```hcl
module "api_gateway" {
  source = "../modules/api-gateway/"

  # General Settings
  api_name    = "stackfood-api"
  description = "StackFood API Gateway with hybrid routing"
  environment = "production"

  # VPC Configuration
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # EKS Integration
  eks_cluster_name = "stackfood-eks"

  # Lambda Integration
  lambda_invoke_arn    = module.lambda["stackfood-auth"].function_invoke_arn
  lambda_function_name = module.lambda["stackfood-auth"].function_name

  # Custom Domain (Optional)
  custom_domain_name   = "api.stackfood.com.br"
  acm_certificate_arn  = module.acm.certificate_arn
  base_path            = ""
  stage_name           = "v1"

  # Security
  vpc_link_name        = "stackfood-vpc-link"
  security_group_name  = "stackfood-api-gateway-sg"

  tags = var.tags

  depends_on = [module.eks, module.nginx-ingress, module.lambda]
}
```

---

## 📤 Outputs

### Principais Outputs

```hcl
# API Gateway Base URL
output.api_gateway_stage_invoke_url
# Example: https://abc123.execute-api.us-east-1.amazonaws.com/v1

# Custom Domain (se configurado)
output.custom_domain_name
# Example: api.stackfood.com.br

# VPC Link ID
output.vpc_link_id

# Microservices Routes
output.microservices_routes
# {
#   customers = {
#     path = "/customers"
#     port = 8084
#     url  = "https://.../v1/customers"
#   }
#   ...
# }

# Routes Summary
output.api_routes_summary
# {
#   base_url = "https://..."
#   routes = {
#     lambda = { auth = "/auth", customer = "/customer" }
#     microservices = { ... }
#   }
#   vpc_link_enabled = true
# }
```

---

## 🔗 Roteamento Detalhado

### Lambda Routes (AWS_PROXY)

**POST /auth**
```
Client → API Gateway → Lambda (stackfood-auth)
                         ↓
                    AWS Cognito
                         ↓
                    Return JWT Token
```

**POST /customer**
```
Client → API Gateway → Lambda (stackfood-auth)
                         ↓
                    PostgreSQL + Cognito
                         ↓
                    Return Customer
```

### Microservices Routes (HTTP_PROXY)

**ANY /customers/{proxy+}**
```
Client → API Gateway → VPC Link → NLB → NGINX Ingress
                                                ↓
                                    stackfood-customers.customers.svc.cluster.local:8084
```

**Exemplos de Requests**:
- `GET /customers/api/customers` → `http://stackfood-customers:8084/api/customers`
- `POST /customers/api/customers` → `http://stackfood-customers:8084/api/customers`
- `GET /customers/api/customers/{id}` → `http://stackfood-customers:8084/api/customers/{id}`

**⚠️ Nota**: O `{proxy+}` captura todo o path após `/customers/` e repassa para o microserviço.

---

## ⚙️ Variáveis de Entrada

### Obrigatórias

| Variável | Tipo | Descrição |
|----------|------|-----------|
| `api_name` | string | Nome do API Gateway |
| `vpc_id` | string | VPC ID onde o API Gateway será deployado |
| `eks_cluster_name` | string | Nome do cluster EKS |
| `lambda_invoke_arn` | string | ARN de invoke da Lambda |
| `lambda_function_name` | string | Nome da função Lambda |

### Opcionais

| Variável | Tipo | Default | Descrição |
|----------|------|---------|-----------|
| `custom_domain_name` | string | `""` | Custom domain (ex: api.stackfood.com.br) |
| `acm_certificate_arn` | string | `""` | ARN do certificado ACM |
| `base_path` | string | `"v1"` | Base path do custom domain |
| `stage_name` | string | `"v1"` | Nome do stage |
| `environment` | string | `"dev"` | Ambiente (dev/prod) |

---

## 🔧 Arquivos do Módulo

```
api-gateway/
├── main.tf                    # Recursos principais (API, Lambda routes)
├── microservices-routes.tf    # Rotas dos microserviços (VPC Link)
├── vpc-link.tf                # VPC Link para EKS
├── data.tf                    # Data sources (NLB, region, etc)
├── locals.tf                  # Variáveis locais
├── variables.tf               # Definição de variáveis
├── output.tf                  # Outputs do módulo
└── README.md                  # Este arquivo
```

---

## 🛠️ Troubleshooting

### VPC Link não conecta ao NLB

**Problema**: VPC Link fica em estado "PENDING" ou "FAILED"

**Solução**:
```bash
# Verificar se NLB existe e está ativo
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(DNSName, `ingress`)].{Name:LoadBalancerName,State:State.Code}'

# Verificar VPC Link
aws apigateway get-vpc-links
```

### Microserviço não responde

**Problema**: Requests retornam 502/504

**Possíveis causas**:
1. **Service não existe no K8s**:
   ```bash
   kubectl get svc stackfood-customers -n customers
   ```

2. **Pods não estão rodando**:
   ```bash
   kubectl get pods -n customers
   ```

3. **Health check falhando**:
   ```bash
   kubectl logs -f deployment/stackfood-customers -n customers
   ```

4. **DNS interno não resolve**:
   ```bash
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- sh
   curl http://stackfood-customers.customers.svc.cluster.local:8084/health
   ```

### Lambda não é invocada

**Problema**: Requests para /auth retornam 403/500

**Solução**:
```bash
# Verificar se Lambda tem permissão
aws lambda get-policy --function-name stackfood-auth

# Verificar logs da Lambda
aws logs tail /aws/lambda/stackfood-auth --follow
```

---

## 📊 Monitoramento

### CloudWatch Metrics

Métricas disponíveis no CloudWatch:
- **Count**: Número de requests
- **4XXError**: Erros de cliente
- **5XXError**: Erros de servidor
- **Latency**: Latência end-to-end
- **IntegrationLatency**: Latência do backend

### Logs

Habilitar logs no API Gateway:

```hcl
resource "aws_api_gateway_stage" "dev" {
  # ... existing config ...

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format         = "$context.requestId"
  }

  xray_tracing_enabled = true
}
```

---

## 🔒 Segurança

### Autenticação

- **Lambda Routes**: Nenhuma autenticação (public)
- **Microservices Routes**: Nenhuma autenticação no API Gateway (autenticação no microserviço)

**💡 Recomendação**: Adicionar Cognito Authorizer ou API Keys

```hcl
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]
}

# Aplicar nos methods
resource "aws_api_gateway_method" "customers_any" {
  # ... existing config ...
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}
```

### Rate Limiting

Configurar throttling no stage:

```hcl
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}
```

---

## 🎯 Próximos Passos

1. ✅ Rotas dos microserviços criadas
2. ⏳ Adicionar Cognito Authorizer
3. ⏳ Configurar WAF (Web Application Firewall)
4. ⏳ Habilitar CloudWatch Logs
5. ⏳ Adicionar API Keys para rate limiting
6. ⏳ Configurar CORS para produção
7. ⏳ Adicionar caching para GET requests

---

## 📚 Referências

- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [VPC Link Documentation](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [API Gateway Best Practices](https://docs.aws.amazon.com/apigateway/latest/developerguide/best-practices.html)

---

**Última atualização**: 2025-12-26
**Versão**: 2.0.0 (Microservices support)
