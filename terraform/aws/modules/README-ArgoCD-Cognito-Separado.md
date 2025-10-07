# ArgoCD com Cognito Dedicado + DNS Cloudflare

## 🎯 **Arquitetura com User Pools Separados**

Esta implementação cria **dois User Pools Cognito completamente independentes**:

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cognito                             │
│  ┌─────────────────┐         ┌─────────────────────────┐   │
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
```

## 🔄 **Mudanças Implementadas**

### ✅ **Novo Arquivo: `argo.tf`**

- User Pool dedicado **exclusivamente** para ArgoCD
- Usuário `stackfood` com senha `Fiap@2025`
- Grupos `argocd-admin` e `argocd-readonly`
- Client OIDC configurado para ArgoCD

### ✅ **Outputs Específicos**

- `argocd_user_pool_id` - ID do User Pool dedicado
- `argocd_client_id` - Client ID específico
- `argocd_client_secret` - Secret para OIDC
- `argocd_issuer_url` - URL do issuer
- `argocd_domain` - Domínio do User Pool

### ✅ **Separação Completa**

- **User Pool Principal**: Para API Gateway e aplicação
- **User Pool ArgoCD**: Exclusivo para autenticação GitOps

## 📁 **Estrutura dos Arquivos**

```
modules/cognito/
├── main.tf          # User Pool principal da aplicação
├── argo.tf          # 🆕 User Pool dedicado ArgoCD
├── variables.tf     # Variáveis para ambos
├── outputs.tf       # Outputs separados
└── data.tf          # Data sources
```

## 🚀 **Como Implementar**

### 1. **User Pool da Aplicação**

```hcl
module "cognito_app" {
  source = "../modules/cognito/"

  user_pool_name      = "stackfood-app"
  environment         = var.environment
  guest_user_password = var.guest_user_password
}
```

### 2. **User Pool Dedicado ArgoCD**

```hcl
module "cognito_argocd" {
  source = "../modules/cognito/"

  user_pool_name           = "stackfood-argocd"
  environment              = var.environment
  stackfood_admin_password = "Fiap@2025"

  argocd_callback_urls = [
    "https://argo.stackfood.com.br/api/dex/callback"
  ]
}
```

### 3. **ArgoCD com Cognito Dedicado**

```hcl
module "argocd" {
  source = "../modules/kubernetes/argocd/"

  # Usar o User Pool dedicado
  cognito_user_pool_id  = module.cognito_argocd.argocd_user_pool_id
  cognito_client_id     = module.cognito_argocd.argocd_client_id
  cognito_client_secret = module.cognito_argocd.argocd_client_secret

  domain_name      = "stackfood.com.br"
  argocd_subdomain = "argo"
}
```

## 🔐 **Configurações de Autenticação**

### **User Pool Aplicação (`stackfood-app`)**

- **Propósito**: API Gateway, aplicação principal
- **Usuários**: `convidado` (guest)
- **Configuração**: CPF como username, autenticação customizada

### **User Pool ArgoCD (`stackfood-argocd`)**

- **Propósito**: Autenticação exclusiva ArgoCD
- **Usuários**: `stackfood` (admin)
- **Configuração**: Email/username, OIDC, grupos de permissão

## 📋 **Outputs Disponíveis**

### **Aplicação Principal**

```hcl
# User Pool da aplicação
user_pool_id              # Para API Gateway
user_pool_client_id       # Cliente da aplicação
api_gateway_authorizer_config  # Configuração completa
```

### **ArgoCD Dedicado**

```hcl
# User Pool dedicado ArgoCD
argocd_user_pool_id       # ID do User Pool ArgoCD
argocd_client_id          # Client ID OIDC
argocd_client_secret      # Secret OIDC (sensitivo)
argocd_issuer_url         # URL do issuer OIDC
argocd_domain             # Domínio do User Pool
argocd_oidc_config        # Configuração completa (sensitivo)
```

## 🎯 **Vantagens da Separação**

### ✅ **Isolamento de Segurança**

- Políticas de acesso independentes
- Rotação de credenciais separada
- Auditoria específica por contexto

### ✅ **Configurações Otimizadas**

- User Pool app: CPF, autenticação customizada
- User Pool ArgoCD: Email, OIDC padrão, grupos

### ✅ **Manutenção Simplificada**

- Mudanças no ArgoCD não afetam a aplicação
- Evolução independente dos sistemas
- Troubleshooting facilitado

## 🔧 **Comandos de Validação**

### **Verificar User Pools criados**

```bash
# Listar User Pools
aws cognito-idp list-user-pools --max-results 20

# Ver detalhes do User Pool ArgoCD
aws cognito-idp describe-user-pool --user-pool-id <argocd-user-pool-id>

# Ver usuários do ArgoCD
aws cognito-idp list-users --user-pool-id <argocd-user-pool-id>
```

### **Testar autenticação ArgoCD**

```bash
# Acessar ArgoCD
curl -I https://argo.stackfood.com.br

# Ver configuração OIDC
kubectl get secret argocd-secret -n argocd -o yaml
```

## 🎯 **Fluxo de Autenticação ArgoCD**

1. **Acesso**: `https://argo.stackfood.com.br`
2. **Redirecionamento**: Para Cognito User Pool ArgoCD
3. **Login**: `stackfood` / `Fiap@2025`
4. **Token**: Cognito retorna token com grupos
5. **Autorização**: ArgoCD verifica grupo `argocd-admin`
6. **Acesso**: Interface ArgoCD com permissões admin

## 📞 **Troubleshooting**

### **Problema: "User not found"**

- Verificar se está usando o User Pool correto (`stackfood-argocd`)
- Confirmar se usuário `stackfood` foi criado

### **Problema: "Invalid client"**

- Verificar se callback URLs estão corretas
- Confirmar client secret no ArgoCD

### **Problema: "Access denied"**

- Verificar se usuário está no grupo `argocd-admin`
- Confirmar configuração RBAC do ArgoCD

---

**⚠️ IMPORTANTE**: Esta configuração cria **dois User Pools independentes**. Certifique-se de usar os outputs corretos (`argocd_*`) para o ArgoCD e os outputs principais (`user_pool_*`) para a aplicação.
