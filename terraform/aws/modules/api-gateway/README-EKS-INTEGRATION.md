# API Gateway + EKS Integration Guide

## Arquitetura da Solução

Esta configuração permite que o API Gateway da AWS seja a porta de entrada única para:

- **Lambda Functions** (paths específicos: `/auth`, `/customer`)
- **Aplicações no EKS** (todos os outros paths via proxy `/{proxy+}`)

### Fluxo de Requisições

```
Cliente
   ↓
api.stackfood.com.br
   ↓
API Gateway (REST API)
   ├─→ /auth/** ──→ Lambda Function
   ├─→ /customer/** ──→ Lambda Function
   └─→ /** (outros paths) ──→ VPC Link ──→ NLB ──→ NGINX Ingress ──→ EKS Pods
```

## Como Funciona

### 1. Roteamento no API Gateway

O API Gateway usa **order of precedence** para rotear requisições:

1. **Paths Específicos (Lambda)** - Maior prioridade

   - `/auth` → Lambda Function
   - `/customer` → Lambda Function

2. **Greedy Path Variable (EKS)** - Menor prioridade
   - `/{proxy+}` → Captura TODOS os outros paths
   - Exemplos: `/products`, `/orders`, `/api/v1/users`, etc.

### 2. Integração com EKS via VPC Link

```
API Gateway
   ↓
VPC Link (conecta API Gateway à VPC)
   ↓
Network Load Balancer (criado pelo NGINX Ingress Controller)
   ↓
NGINX Ingress Controller
   ↓
Service ClusterIP (stackfood-api)
   ↓
Pods da Aplicação
```

### 3. Configuração do NGINX Ingress

- **Protocol**: HTTP (porta 80)
- **Host Header**: `api.stackfood.com.br` é preservado
- **SSL**: Terminado no API Gateway, não no NGINX
- **CORS**: Gerenciado pelo API Gateway

## Configurações Importantes

### API Gateway

- **Integration Type**: `HTTP_PROXY` (passa requisições sem modificação)
- **Connection Type**: `VPC_LINK` (conecta à VPC do EKS)
- **Host Header**: Injeta `api.stackfood.com.br` para o NGINX rotear corretamente
- **Timeout**: 29 segundos (máximo permitido)

### VPC Link

- **Target**: ARN do Network Load Balancer do NGINX Ingress
- **Tags**: Busca por tags:
  - `kubernetes.io/service-name` = `ingress-nginx/ingress-nginx-controller`
  - `kubernetes.io/cluster/<cluster-name>` = `owned`

### NGINX Ingress

- **Backend Protocol**: HTTP (não HTTPS)
- **SSL Redirect**: Desabilitado (SSL já terminado no API Gateway)
- **Forwarded Headers**: Habilitado (preserva headers originais)
- **Service Port**: 80 (HTTP)

## Testando a Integração

### 1. Verificar VPC Link

```bash
# Obter ID do VPC Link
terraform output -json | jq -r '.api_gateway_vpc_link_id.value'

# Verificar status (deve ser AVAILABLE)
aws apigateway get-vpc-link --vpc-link-id <vpc-link-id>
```

### 2. Verificar NLB

```bash
# Listar Network Load Balancers
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `nginx`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' \
  --output table

# Verificar health checks
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

### 3. Testar Endpoints

```bash
# Testar Lambda (deve funcionar)
curl -X POST https://api.stackfood.com.br/v1/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "test", "password": "test"}'

# Testar EKS (deve funcionar)
curl https://api.stackfood.com.br/v1/products

# Testar outro endpoint EKS
curl https://api.stackfood.com.br/v1/orders
```

### 4. Debug

```bash
# Logs do NGINX Ingress Controller
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f

# Verificar Ingress
kubectl get ingress -n production
kubectl describe ingress stackfood-api -n production

# Verificar Service
kubectl get svc stackfood-api -n production
kubectl describe svc stackfood-api -n production

# Testar diretamente o NLB (bypass API Gateway)
curl http://<nlb-dns-name>/ -H "Host: api.stackfood.com.br"
```

## Troubleshooting

### Problema: VPC Link em estado FAILED

**Causa**: NLB não está "active" ou não foi encontrado.

**Solução**:

```bash
# Verificar estado do NLB
aws elbv2 describe-load-balancers \
  --load-balancer-arns <nlb-arn> \
  --query 'LoadBalancers[0].State.Code'

# Aguardar até que esteja "active"
# O Terraform tem um wait de 5 minutos (20 tentativas × 15s)
```

### Problema: 503 Service Unavailable

**Causa**: Targets do NLB não estão healthy.

**Solução**:

```bash
# Verificar health dos targets
kubectl get pods -n production -l app=stackfood-api

# Verificar se os pods estão rodando
kubectl logs -n production -l app=stackfood-api

# Verificar service endpoints
kubectl get endpoints stackfood-api -n production
```

### Problema: 404 Not Found

**Causa**: NGINX não está roteando corretamente.

**Solução**:

```bash
# Verificar se o Host header está correto
# O API Gateway deve injetar "Host: api.stackfood.com.br"

# Testar diretamente no pod
kubectl port-forward -n production <pod-name> 8080:5039
curl http://localhost:8080/health
```

### Problema: CORS Errors

**Causa**: Respostas OPTIONS não configuradas corretamente.

**Solução**:

- O API Gateway responde a requisições OPTIONS com headers CORS
- O NGINX Ingress tem CORS desabilitado para não duplicar
- Verificar se `nginx.ingress.kubernetes.io/enable-cors: "false"`

### Problema: Timeout (504 Gateway Timeout)

**Causa**: Aplicação demora mais de 29 segundos para responder.

**Solução**:

```bash
# Aumentar timeout no deployment da aplicação
# Ou otimizar a performance da aplicação
# 29 segundos é o máximo permitido no API Gateway
```

## Monitoramento

### CloudWatch Metrics

```bash
# API Gateway
- IntegrationLatency
- Latency
- 4XXError
- 5XXError
- Count

# VPC Link
- VpcLinkStatus
```

### Logs

```bash
# Habilitar logs do API Gateway (opcional)
# Stage > Logs/Tracing > Enable CloudWatch Logs

# Visualizar logs
aws logs tail /aws/apigateway/<api-id>/<stage-name> --follow
```

## Custos

- **API Gateway**: ~$3.50 por milhão de requisições
- **VPC Link**: ~$0.01 por hora + $0.01 por GB transferido
- **NLB**: ~$0.0225 por hora + $0.006 por LCU
- **Data Transfer**: ~$0.09 por GB (entre AZs)

## Próximos Passos

1. ✅ Configurar custom domain com certificado ACM
2. ✅ Configurar VPC Link para conectar API Gateway ao EKS
3. ✅ Configurar rotas no API Gateway (Lambda + EKS proxy)
4. ✅ Configurar NGINX Ingress para aceitar requisições do VPC Link
5. 🔄 Testar todos os endpoints
6. 🔄 Configurar monitoring e alertas
7. 🔄 Configurar WAF (Web Application Firewall) - opcional
8. 🔄 Configurar rate limiting e throttling

## Referências

- [AWS API Gateway VPC Link](https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-private-integration.html)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [API Gateway HTTP Proxy Integration](https://docs.aws.amazon.com/apigateway/latest/developerguide/setup-http-integrations.html)
