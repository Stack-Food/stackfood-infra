# ArgoCD com Módulo Cognito Unificado + DNS Dedicado

## 🎯 **Nova Arquitetura - Um Módulo, Dois User Pools**

Esta implementação cria **UM módulo Cognito** que gerencia **DOIS User Pools independentes**, organizados em arquivos separados:

```
┌─────────────────────────────────────────────────────────────┐
│                Módulo Cognito Unificado                    │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
│  │app-user-pool.tf │         │argocd-user-pool.tf     │   │
│  │                 │         │                         │   │
│  │ User Pool APP   │         │ User Pool ArgoCD        │   │
│  │ stackfood-app   │         │ stackfood-argocd        │   │
│  │                 │         │                         │   │
│  │ • API Gateway   │         │ • ArgoCD OIDC          │   │
│  │ • Aplicação     │         │ • Usuário: stackfood    │   │
│  │ • Usuário Guest │         │ • Grupos: admin/readonly│   │
│  └─────────────────┘         └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
            │                              │
            ▼                              ▼
┌─────────────────┐                ┌─────────────────┐
│   Aplicação     │                │     ArgoCD      │
│   Principal     │                │   GitOps Tool   │
└─────────────────┘                └─────────────────┘
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Módulo DNS Dedicado                     │
│                      modules/dns/                          │
│                                                             │
│  • Registros Cloudflare                                   │
│  • argo.stackfood.com.br → Load Balancer                  │
│  • Configuração específica para EKS                       │
└─────────────────────────────────────────────────────────────┘
```

## 🏗️ **Estrutura dos Módulos**

### **📁 Módulo Cognito Unificado (`modules/cognito/`)**

```
modules/cognito/
├── main.tf                  # 🎯 Orquestração e configurações compartilhadas
├── app-user-pool.tf         # 🍔 User Pool da aplicação
├── argocd-user-pool.tf      # 🚀 User Pool do ArgoCD
├── variables.tf             # ⚙️ Variáveis para ambos os User Pools
├── outputs.tf               # 📤 Outputs organizados por User Pool
└── data.tf                  # 📊 Data sources compartilhados
```

### **📁 Módulo DNS Dedicado (`modules/dns/`)**

```
modules/dns/
├── main.tf                  # 🌐 Registros DNS Cloudflare
├── variables.tf             # ⚙️ Configurações DNS
├── output.tf                # 📤 Outputs DNS
├── providers.tf             # 🔌 Provider Cloudflare
└── data.tf                  # 📊 Data sources EKS/Load Balancer
```

## 🎮 **Como Usar o Módulo Unificado**

### **1. Configuração Única**

```hcl
module "cognito" {
  source = "../modules/cognito/"

  # Configurações gerais
  user_pool_name = "stackfood"
  environment    = "prod"

  # Controlar quais User Pools criar
  create_app_user_pool    = true  # User Pool aplicação
  create_argocd_user_pool = true  # User Pool ArgoCD

  # Configurações específicas
  guest_user_password      = "MinhaSenhaForte123!"
  stackfood_admin_password = "Fiap@2025"

  argocd_callback_urls = [
    "https://argo.stackfood.com.br/api/dex/callback"
  ]
}
```

### **2. Usar Outputs Específicos**

```hcl
# Para API Gateway (aplicação)
authorizer_config = module.cognito.api_gateway_authorizer_config

# Para ArgoCD
argocd_config = {
  user_pool_id  = module.cognito.argocd_user_pool_id
  client_id     = module.cognito.argocd_client_id
  client_secret = module.cognito.argocd_client_secret
}
```

### **3. Módulo DNS Separado**

```hcl
module "dns" {
  source = "../modules/dns/"

  cloudflare_zone_id   = var.cloudflare_zone_id
  domain_name          = "stackfood.com.br"
  eks_cluster_name     = "stackfood-cluster"
  create_argocd_record = true
  argocd_subdomain     = "argo"
}
```

## 🔐 **Controle Granular**

### **Criar Apenas User Pool da Aplicação**

```hcl
module "cognito" {
  source = "../modules/cognito/"

  user_pool_name          = "stackfood"
  create_app_user_pool    = true   # ✅ Criar
  create_argocd_user_pool = false  # ❌ Não criar

  guest_user_password = var.guest_password
  # stackfood_admin_password não é necessário
}
```

### **Criar Apenas User Pool ArgoCD**

```hcl
module "cognito" {
  source = "../modules/cognito/"

  user_pool_name          = "stackfood"
  create_app_user_pool    = false  # ❌ Não criar
  create_argocd_user_pool = true   # ✅ Criar

  stackfood_admin_password = "Fiap@2025"
  # guest_user_password não é necessário
}
```

## 📊 **Outputs Organizados**

### **User Pool Aplicação**

```hcl
module.cognito.app_user_pool_id
module.cognito.app_user_pool_arn
module.cognito.app_user_pool_client_id
module.cognito.api_gateway_authorizer_config
```

### **User Pool ArgoCD**

```hcl
module.cognito.argocd_user_pool_id
module.cognito.argocd_client_id
module.cognito.argocd_client_secret
module.cognito.argocd_issuer_url
module.cognito.argocd_oidc_config
```

### **Compatibilidade (Deprecated)**

```hcl
# Ainda funcionam para compatibilidade
module.cognito.user_pool_id          # → app_user_pool_id
module.cognito.user_pool_client_id   # → app_user_pool_client_id
```

## 🎯 **Vantagens da Nova Arquitetura**

### ✅ **Organização Clara**

- **Um módulo** para gerenciar ambos os User Pools
- **Arquivos separados** para cada finalidade
- **Configurações específicas** para cada contexto

### ✅ **Flexibilidade Total**

- Criar ambos os User Pools ou apenas um
- Configurações independentes
- Outputs específicos para cada uso

### ✅ **Manutenção Simplificada**

- Todas as configurações Cognito em um lugar
- Versionamento unificado
- Dependências gerenciadas centralmente

### ✅ **Módulo DNS Dedicado**

- Responsabilidade única: DNS
- Integração específica com EKS
- Reutilizável para outros serviços

## 🚀 **Exemplo Completo**

```hcl
# Cognito unificado
module "cognito" {
  source = "../modules/cognito/"

  user_pool_name = "stackfood"
  environment    = "prod"

  create_app_user_pool    = true
  create_argocd_user_pool = true

  guest_user_password      = var.guest_password
  stackfood_admin_password = "Fiap@2025"

  argocd_callback_urls = ["https://argo.stackfood.com.br/api/dex/callback"]
}

# DNS dedicado
module "dns" {
  source = "../modules/dns/"

  cloudflare_zone_id   = var.cloudflare_zone_id
  domain_name          = "stackfood.com.br"
  eks_cluster_name     = "stackfood-cluster"
  create_argocd_record = true
}

# ArgoCD
module "argocd" {
  source = "../modules/kubernetes/argocd/"

  domain_name           = "stackfood.com.br"
  cognito_user_pool_id  = module.cognito.argocd_user_pool_id
  cognito_client_id     = module.cognito.argocd_client_id
  cognito_client_secret = module.cognito.argocd_client_secret
  cognito_region        = "us-east-1"
}
```

## 📋 **Migração da Versão Anterior**

### **De:**

```hcl
# Antes: dois módulos separados
module "cognito_app" { source = "../modules/cognito/" }
module "cognito_argocd" { source = "../modules/cognito/" }
module "dns_argocd" { source = "../modules/dns-cloudflare/" }
```

### **Para:**

```hcl
# Agora: módulos especializados
module "cognito" { source = "../modules/cognito/" }
module "dns" { source = "../modules/dns/" }
```

## 🔧 **Comandos de Validação**

```bash
# Ver User Pools criados
aws cognito-idp list-user-pools --max-results 20

# Ver usuários em cada User Pool
aws cognito-idp list-users --user-pool-id <app-user-pool-id>
aws cognito-idp list-users --user-pool-id <argocd-user-pool-id>

# Testar DNS
nslookup argo.stackfood.com.br
curl -I https://argo.stackfood.com.br
```

## 🎯 **Resultado Final**

- ✅ **Um módulo Cognito** que cria dois User Pools
- ✅ **Arquivos organizados** por funcionalidade
- ✅ **Módulo DNS dedicado** para registros Cloudflare
- ✅ **Outputs específicos** para cada uso
- ✅ **Controle granular** de criação
- ✅ **Usuário stackfood** com senha `Fiap@2025` no ArgoCD

---

**💡 IMPORTANTE**: Esta nova arquitetura mantém a **separação lógica** dos User Pools, mas os **organiza em um módulo unificado** para facilitar gerenciamento e manutenção.
