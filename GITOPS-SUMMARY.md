# 🎯 StackFood - GitOps Implementation Summary

Resumo completo da implementação GitOps para todos os microserviços StackFood.

---

## ✅ O QUE FOI CRIADO

### 📦 Microserviços com Manifestos K8s Completos

Cada repositório de microserviço agora tem sua própria estrutura GitOps:

#### 1. **stackfood-api-customers** (Port 8084)
```
stackfood-api-customers/
└── k8s/
    ├── base/
    │   ├── deployment.yaml       # 2 replicas, HPA 2-10
    │   ├── service.yaml          # ClusterIP:8084
    │   ├── hpa.yaml              # Auto-scaling
    │   └── kustomization.yaml
    ├── prod/
    │   ├── configmap.yaml        # Cognito, PostgreSQL, SNS
    │   ├── secret.yaml           # Passwords, AWS creds
    │   └── kustomization.yaml
    ├── argocd-application.yaml   # GitOps Application
    └── README.md
```

#### 2. **stackfood-api-product** (Port 8080)
```
stackfood-api-product/
└── k8s/
    ├── base/ (deployment, service, hpa, kustomization)
    ├── prod/ (configmap, secret, kustomization)
    └── argocd-application.yaml
```

#### 3. **stackfood-api-orders** (Port 8081)
```
stackfood-api-orders/
└── k8s/
    ├── base/
    ├── prod/ (configmap com SNS/SQS URLs)
    └── argocd-application.yaml
```

#### 4. **stackfood-api-payments** (Port 8082)
```
stackfood-api-payments/
└── k8s/
    ├── base/
    ├── prod/ (configmap com DynamoDB, SNS/SQS)
    └── argocd-application.yaml
```

#### 5. **stackfood-api-production** (Port 8083)
```
stackfood-api-production/
└── k8s/
    ├── base/
    ├── prod/ (configmap com SNS/SQS)
    └── argocd-application.yaml
```

---

## 🔗 COMUNICAÇÃO ENTRE MICROSERVIÇOS

### DNS Interno do Cluster

Todos os serviços se comunicam via DNS interno do Kubernetes:

| Serviço | DNS Interno | Porta |
|---------|-------------|-------|
| Customers | `stackfood-customers.customers.svc.cluster.local` | 8084 |
| Products | `stackfood-products.products.svc.cluster.local` | 8080 |
| Orders | `stackfood-orders.orders.svc.cluster.local` | 8081 |
| Payments | `stackfood-payments.payments.svc.cluster.local` | 8082 |
| Production | `stackfood-production.production.svc.cluster.local` | 8083 |

### Exemplo de Configuração

**Orders ConfigMap** chama Products:
```yaml
ExternalServices__ProductsApiUrl: "http://stackfood-products.products.svc.cluster.local:8080"
```

---

## 🌐 ACESSO EXTERNO VIA API GATEWAY

### Arquitetura de Roteamento

```
Cliente (Internet)
    ↓
AWS API Gateway (api.stackfood.com.br)
    ↓
VPC Link
    ↓
Network Load Balancer (NLB)
    ↓
NGINX Ingress Controller
    ↓
Microserviços (ClusterIP Services)
```

### Rotas Esperadas

| Rota Externa | Microserviço | Namespace | Porta |
|--------------|--------------|-----------|-------|
| `https://api.stackfood.com.br/customers/*` | customers | customers | 8084 |
| `https://api.stackfood.com.br/products/*` | products | products | 8080 |
| `https://api.stackfood.com.br/orders/*` | orders | orders | 8081 |
| `https://api.stackfood.com.br/payments/*` | payments | payments | 8082 |
| `https://api.stackfood.com.br/production/*` | production | production | 8083 |

**⚠️ PRÓXIMO PASSO**: Atualizar o módulo `terraform/aws/modules/api-gateway/` para adicionar rotas para cada microserviço.

---

## 🚀 DEPLOYMENT WORKFLOW

### GitOps Automático com ArgoCD

```
1. Developer commita mudança no código
   ↓
2. CI/CD builda Docker image
   ↓
3. Push para ghcr.io/stack-food/stackfood-api-<service>:latest
   ↓
4. Developer atualiza k8s/prod/kustomization.yaml (opcional: mudar tag)
   ↓
5. ArgoCD detecta mudança no Git automaticamente
   ↓
6. ArgoCD sincroniza manifestos com o cluster
   ↓
7. Kubernetes faz rolling update (zero downtime)
```

### Como Deployar TUDO de Uma Vez

#### Opção 1: Script Automatizado

```bash
cd stackfood-infra
./scripts/deploy-all-microservices.sh
```

#### Opção 2: Manual (um por um)

```bash
# Customers
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-customers/main/k8s/argocd-application.yaml

# Products
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-product/main/k8s/argocd-application.yaml

# Orders
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-orders/main/k8s/argocd-application.yaml

# Payments
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-payments/main/k8s/argocd-application.yaml

# Production
kubectl apply -f https://raw.githubusercontent.com/Stack-Food/stackfood-api-production/main/k8s/argocd-application.yaml
```

---

## ⚙️ CONFIGURAÇÃO NECESSÁRIA

### 1. Image Pull Secrets

Criar em cada namespace:

```bash
for ns in customers products orders payments production; do
  kubectl create secret docker-registry ghcr-secret \
    --docker-server=ghcr.io \
    --docker-username=<GITHUB_USER> \
    --docker-password=<GITHUB_PAT> \
    --docker-email=<EMAIL> \
    -n $ns
done
```

### 2. ConfigMaps (Atualizar com valores reais)

Cada microserviço tem variáveis que precisam ser atualizadas no arquivo `k8s/prod/configmap.yaml`:

#### Customers:
- `Cognito__UserPoolId`
- `Cognito__ClientId`
- `AWS__SNS__CustomerEventsTopicArn`

#### Orders:
- `AWS__SNS__OrderCreatedTopicArn`
- `AWS__SQS__PaymentEventsQueueUrl`
- `AWS__SQS__ProductionEventsQueueUrl`

#### Payments:
- `DYNAMODB_TABLE_NAME`
- `AWS__SNS__PaymentEventsTopicArn`
- `AWS__SQS__OrderEventsQueueUrl`

#### Production:
- `AWS__SNS__TopicArn`
- `AWS__SQS__QueueUrl`

### 3. Secrets (Atualizar credenciais)

Arquivo `k8s/prod/secret.yaml` em cada repo:

- `POSTGRES_PASSWORD`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**⚠️ IMPORTANTE**: Após atualizar no Git, o ArgoCD sincroniza e reinicia os pods automaticamente.

---

## 📊 MONITORAMENTO E TROUBLESHOOTING

### Verificar Status das Applications

```bash
kubectl get applications -n argocd
```

### Verificar Pods

```bash
kubectl get pods -A | grep stackfood
```

### Ver Logs

```bash
kubectl logs -f deployment/stackfood-customers -n customers
kubectl logs -f deployment/stackfood-orders -n orders
```

### Testar Comunicação Interna

```bash
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- sh

# Dentro do pod:
curl http://stackfood-products.products.svc.cluster.local:8080/health
curl http://stackfood-customers.customers.svc.cluster.local:8084/health
```

### Force Sync (Se necessário)

```bash
argocd app sync customers
argocd app sync products
argocd app sync orders
argocd app sync payments
argocd app sync production
```

---

## 🎯 PRÓXIMOS PASSOS

### 1. ✅ Atualizar API Gateway (stackfood-infra) - COMPLETED

Editar: `terraform/aws/modules/api-gateway/main.tf`

✅ Rotas criadas para todos os microserviços:
- `/customers/*` → VPC Link → NLB → NGINX → stackfood-customers:8084
- `/products/*` → stackfood-products:8080
- `/orders/*` → stackfood-orders:8081
- `/payments/*` → stackfood-payments:8082
- `/production/*` → stackfood-production:8083

**Files Modified:**
- `terraform/aws/modules/api-gateway/microservices-routes.tf` (NEW)
- `terraform/aws/modules/api-gateway/main.tf` (deployment triggers)
- `terraform/aws/modules/api-gateway/output.tf` (outputs)
- `terraform/aws/modules/api-gateway/README.md` (documentation)

### 2. ✅ Configurar SNS/SQS Subscriptions - COMPLETED

Atualizar: `terraform/aws/main/main.tf`

✅ Messaging infrastructure configurada:
- 4 SNS Topics criados (customer, order, payment, production events)
- 4 SQS Queues criadas + 4 DLQs
- 8 SNS → SQS Subscriptions com filter policies
- Terraform outputs para fácil acesso aos ARNs/URLs

**Files Created:**
- `terraform/aws/main/messaging.tf` (SNS/SQS configuration)
- `MESSAGING-INFRASTRUCTURE.md` (complete documentation)
- `DEPLOY-MESSAGING.md` (deployment guide)

**Files Modified:**
- `terraform/aws/main/main.tf` (use local vars instead of var)
- `terraform/aws/main/output.tf` (messaging outputs)

### 3. ⏳ Configurar CI/CD

Para cada repositório, criar `.github/workflows/deploy.yml`:

```yaml
name: Build and Push Docker Image
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build and push
        run: |
          docker build -t ghcr.io/stack-food/stackfood-api-<service>:latest .
          docker push ghcr.io/stack-food/stackfood-api-<service>:latest
```

### 4. ⏳ Testar Fluxo End-to-End

1. Criar produto (POST /products)
2. Criar pedido (POST /orders)
3. Processar pagamento (via SQS)
4. Iniciar produção (via SQS)
5. Finalizar pedido (via SQS)

---

## 📚 DOCUMENTAÇÃO CRIADA

| Arquivo | Localização | Descrição |
|---------|-------------|-----------|
| **README.md** | stackfood-infra/ | Overview geral do projeto |
| **GITOPS-SUMMARY.md** | stackfood-infra/ | Este arquivo (resumo executivo) |
| **DEPLOYMENT-GUIDE.md** | stackfood-infra/ | Guia completo de deployment (infra + microservices + messaging) |
| **ARCHITECTURE.md** | stackfood-infra/ | Documentação técnica detalhada (API Gateway + Messaging) |
| **deploy-all-microservices.sh** | stackfood-infra/scripts/ | Script automatizado de deploy |
| **app-of-apps.yaml** | stackfood-infra/apps/ | App of Apps ArgoCD (opcional) |

---

## ✅ CHECKLIST DE DEPLOY

- [ ] Infraestrutura AWS provisionada (Terraform)
- [ ] EKS Cluster acessível (kubeconfig configurado)
- [ ] ArgoCD instalado no cluster
- [ ] NGINX Ingress Controller instalado
- [ ] Image Pull Secrets criados em todos os namespaces
- [ ] ConfigMaps atualizados com valores reais (ARNs, URLs)
- [ ] Secrets atualizados com credenciais
- [ ] ArgoCD Applications aplicadas (via script ou manual)
- [ ] Pods rodando em todos os namespaces
- [ ] Services criados e com endpoints
- [x] API Gateway roteando para microserviços (CONFIGURED)
- [x] SNS/SQS configurados (CONFIGURED - needs Terraform apply)
- [ ] SNS/SQS ARNs/URLs atualizados nos ConfigMaps
- [ ] Teste end-to-end completo

---

## 💡 BENEFÍCIOS DA IMPLEMENTAÇÃO

✅ **GitOps Real**: Cada time gerencia seus próprios manifestos
✅ **Autonomia**: Microserviços independentes
✅ **Auto-sync**: ArgoCD detecta mudanças automaticamente
✅ **Zero Downtime**: Rolling updates configurados
✅ **Observabilidade**: Health checks, Prometheus metrics
✅ **Auto-scaling**: HPA configurado (CPU/Memory)
✅ **Isolamento**: Namespaces separados
✅ **Comunicação Segura**: DNS interno do cluster

---

**Data de criação**: 2025-12-26
**Última atualização**: 2025-12-26
**Versão**: 1.0.0

---

🚀 **StackFood - Microservices + GitOps + ArgoCD + EKS**
