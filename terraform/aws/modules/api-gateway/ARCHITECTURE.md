# Arquitetura: API Gateway + Lambda + EKS

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                            Cliente (Browser/App)                            │
│                                                                             │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 │ HTTPS
                                 │ api.stackfood.com.br
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                         Route 53 / Cloudflare DNS                           │
│                                                                             │
│                     CNAME: api.stackfood.com.br                             │
│                     ────────────────────────────                            │
│                     Target: API Gateway Regional Domain                     │
│                                                                             │
└────────────────────────────────┬────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                        AWS API Gateway (REST API)                           │
│                        Custom Domain: api.stackfood.com.br                  │
│                        ACM Certificate (SSL/TLS)                            │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                        Path-based Routing                              │ │
│  │                                                                        │ │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────────┐   │ │
│  │  │  /auth/**       │  │  /customer/**   │  │  /{proxy+}         │   │ │
│  │  │  (POST)         │  │  (POST)         │  │  (ANY method)      │   │ │
│  │  │  ↓              │  │  ↓              │  │  ↓                 │   │ │
│  │  │  AWS_PROXY      │  │  AWS_PROXY      │  │  HTTP_PROXY        │   │ │
│  │  └─────────────────┘  └─────────────────┘  └────────────────────┘   │ │
│  │          │                     │                      │              │ │
│  └──────────┼─────────────────────┼──────────────────────┼──────────────┘ │
│             │                     │                      │                │
└─────────────┼─────────────────────┼──────────────────────┼────────────────┘
              │                     │                      │
              │                     │                      │
              ▼                     ▼                      ▼
    ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐
    │                  │  │                  │  │                      │
    │  Lambda Function │  │  Lambda Function │  │     VPC Link         │
    │  (stackfood-auth)│  │  (stackfood-auth)│  │  (Private Network)   │
    │                  │  │                  │  │                      │
    │  - Authentication│  │  - Customer Mgmt │  └──────────┬───────────┘
    │  - Token Gen     │  │  - User Creation │             │
    │                  │  │                  │             │
    └──────────────────┘  └──────────────────┘             │
                                                            │
                                                            ▼
                                              ┌──────────────────────────┐
                                              │                          │
                                              │  Network Load Balancer   │
                                              │  (Created by NGINX)      │
                                              │                          │
                                              │  - Listener: 80 (HTTP)   │
                                              │  - Listener: 443 (HTTPS) │
                                              │                          │
                                              └──────────┬───────────────┘
                                                         │
                                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                            Amazon EKS Cluster                               │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                        │ │
│  │                       NGINX Ingress Controller                         │ │
│  │                       (DaemonSet/Deployment)                           │ │
│  │                                                                        │ │
│  │  Rules:                                                                │ │
│  │  - Host: api.stackfood.com.br                                          │ │
│  │  - Path: / (Prefix)                                                    │ │
│  │  - Backend: stackfood-api service                                      │ │
│  │                                                                        │ │
│  └───────────────────────────────┬────────────────────────────────────────┘ │
│                                  │                                          │
│                                  ▼                                          │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                                                                        │ │
│  │                    Service: stackfood-api (ClusterIP)                  │ │
│  │                                                                        │ │
│  │                    Port 80 → targetPort 5039 (HTTP)                    │ │
│  │                                                                        │ │
│  └───────────────────────────────┬────────────────────────────────────────┘ │
│                                  │                                          │
│                                  │ Load Balance                             │
│                                  ▼                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │                  │  │                  │  │                  │         │
│  │  Pod             │  │  Pod             │  │  Pod             │         │
│  │  stackfood-api   │  │  stackfood-api   │  │  stackfood-api   │         │
│  │                  │  │                  │  │                  │         │
│  │  Container:      │  │  Container:      │  │  Container:      │         │
│  │  Port 5039       │  │  Port 5039       │  │  Port 5039       │         │
│  │                  │  │                  │  │                  │         │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════

                            Request Flow Examples

═══════════════════════════════════════════════════════════════════════════════

Example 1: Authentication (Lambda)
───────────────────────────────────

Request:
  POST https://api.stackfood.com.br/v1/auth
  Body: { "username": "user", "password": "pass" }

Flow:
  1. Cliente → Route 53/Cloudflare
  2. Route 53/Cloudflare → API Gateway
  3. API Gateway identifica path /v1/auth
  4. API Gateway roteia para Lambda (AWS_PROXY)
  5. Lambda processa autenticação
  6. Lambda retorna token JWT
  7. API Gateway retorna resposta ao cliente

───────────────────────────────────────────────────────────────────────────────

Example 2: Product List (EKS)
──────────────────────────────

Request:
  GET https://api.stackfood.com.br/v1/products

Flow:
  1. Cliente → Route 53/Cloudflare
  2. Route 53/Cloudflare → API Gateway
  3. API Gateway identifica path /v1/products (não é /auth ou /customer)
  4. API Gateway usa integração HTTP_PROXY via VPC Link
  5. VPC Link → Network Load Balancer
  6. NLB → NGINX Ingress Controller
  7. NGINX Ingress → Service stackfood-api
  8. Service → Pod da aplicação (porta 5039)
  9. Pod processa requisição
  10. Resposta retorna pelo mesmo caminho

───────────────────────────────────────────────────────────────────────────────

Example 3: Create Order (EKS)
──────────────────────────────

Request:
  POST https://api.stackfood.com.br/v1/orders
  Headers: Authorization: Bearer <token>
  Body: { "items": [...], "total": 100 }

Flow:
  1. Cliente → Route 53/Cloudflare
  2. Route 53/Cloudflare → API Gateway
  3. API Gateway identifica path /v1/orders (capturado por /{proxy+})
  4. API Gateway usa integração HTTP_PROXY via VPC Link
  5. VPC Link → Network Load Balancer
  6. NLB → NGINX Ingress Controller (preserva path e headers)
  7. NGINX Ingress → Service stackfood-api
  8. Service → Pod da aplicação (porta 5039)
  9. Pod valida token JWT (gerado pela Lambda)
  10. Pod cria pedido no banco de dados
  11. Resposta retorna pelo mesmo caminho

═══════════════════════════════════════════════════════════════════════════════

                            Key Configuration Points

═══════════════════════════════════════════════════════════════════════════════

API Gateway:
  ✓ Custom domain com ACM certificate
  ✓ Stage: v1
  ✓ Base path: v1 (todas as rotas começam com /v1)
  ✓ VPC Link conectado ao NLB
  ✓ HTTP_PROXY integration (preserva path original)
  ✓ Host header injection: "Host: api.stackfood.com.br"
  ✓ Timeout: 29 segundos

VPC Link:
  ✓ Target: ARN do NLB criado pelo NGINX Ingress
  ✓ Security: Privado, sem exposição à internet
  ✓ Status: AVAILABLE (critical!)

Network Load Balancer:
  ✓ Type: Network (Layer 4)
  ✓ Scheme: Internal (privado)
  ✓ Created by: NGINX Ingress Controller
  ✓ Listeners: 80 (HTTP), 443 (HTTPS)
  ✓ Health checks: TCP

NGINX Ingress:
  ✓ Host: api.stackfood.com.br
  ✓ Path: / (prefix)
  ✓ Backend protocol: HTTP (não HTTPS)
  ✓ SSL redirect: disabled
  ✓ CORS: disabled (gerenciado pelo API Gateway)
  ✓ Forwarded headers: enabled

Kubernetes Service:
  ✓ Type: ClusterIP (interno)
  ✓ Port: 80 → targetPort: 5039
  ✓ Selector: app=stackfood-api

═══════════════════════════════════════════════════════════════════════════════

                                 Security

═══════════════════════════════════════════════════════════════════════════════

1. SSL/TLS:
   - Terminado no API Gateway (ACM certificate)
   - Comunicação interna: HTTP (dentro da VPC)
   - Sem exposição de HTTP público

2. Network:
   - NLB é interno (não tem IP público)
   - VPC Link faz ponte segura
   - Pods não expostos diretamente

3. Authentication:
   - Lambda gera tokens JWT
   - EKS valida tokens JWT nas requisições
   - API Gateway pode ter authorizers (opcional)

4. CORS:
   - Gerenciado centralmente no API Gateway
   - Respostas OPTIONS configuradas
   - Headers corretos em todas as respostas

═══════════════════════════════════════════════════════════════════════════════
```
