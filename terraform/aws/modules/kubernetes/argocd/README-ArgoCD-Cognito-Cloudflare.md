# ArgoCD com Autenticação Cognito e DNS Cloudflare

Este guia mostra como implementar ArgoCD com autenticação via AWS Cognito e registros DNS automatizados na Cloudflare.

## 📋 Pré-requisitos

- Cluster EKS funcional
- NGINX Ingress Controller instalado
- Acesso às APIs da Cloudflare
- Credenciais AWS configuradas
- Terraform >= 1.0

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   AWS Cognito   │    │      EKS        │
│   DNS Records   │◄──►│   User Pool     │◄──►│   ArgoCD        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Implementação

### 1. Configurar Variáveis

Adicione as seguintes variáveis ao seu `variables.tf`:

```hcl
variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "domain_name" {
  description = "Domain name principal"
  type        = string
  default     = "stackfood.com.br"
}

variable "guest_user_password" {
  description = "Senha do usuário convidado do Cognito"
  type        = string
  sensitive   = true
}
```

### 2. Configurar o Provider Cloudflare

```hcl
# providers.tf
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
```

### 3. Usar os Módulos

Copie o exemplo do arquivo `argocd-integration-example.tf` e adapte conforme sua necessidade.

## 📊 Módulos Criados

### 1. DNS Cloudflare (`modules/dns-cloudflare`)

**Funcionalidades:**
- Criação de registros DNS para ArgoCD
- Suporte a registros genéricos
- Integração com Cloudflare API
- Tags automáticas

**Exemplo de uso:**
```hcl
module "dns_argocd" {
  source = "../modules/dns-cloudflare/"
  
  cloudflare_zone_id     = var.cloudflare_zone_id
  domain_name           = var.domain_name
  load_balancer_dns_name = "k8s-ingress-12345.elb.amazonaws.com"
  
  # Opcional
  argocd_subdomain = "argo"
  proxied         = false
  ttl             = 300
}
```

### 2. ArgoCD Kubernetes (`modules/kubernetes/argocd`)

**Funcionalidades:**
- Instalação via Helm Chart
- Configuração OIDC automática
- Templates personalizáveis
- Integração com Cognito

**Exemplo de uso:**
```hcl
module "argocd" {
  source = "../modules/kubernetes/argocd/"
  
  domain_name           = "stackfood.com.br"
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.argocd_client_id
  cognito_client_secret = module.cognito.argocd_client_secret
  cognito_region        = "us-east-1"
}
```

### 3. Cognito Enhanced (`modules/cognito`)

**Funcionalidades originais mantidas:**
- User Pool configurado
- Cliente para API Gateway

**Novas funcionalidades adicionadas:**
- Usuário `stackfood` com senha `Fiap@2025`
- Grupos `argocd-admin` e `argocd-readonly`
- Cliente OIDC específico para ArgoCD
- Outputs otimizados para integração

## 🔐 Configuração de Autenticação

### Usuários Criados Automaticamente

1. **stackfood** (Admin)
   - Username: `stackfood`
   - Password: `Fiap@2025`
   - Grupo: `argocd-admin`
   - Permissões: Administrador completo do ArgoCD

2. **convidado** (Guest)
   - Username: `convidado`
   - Password: Definida pela variável `guest_user_password`
   - Sem acesso ao ArgoCD

### Fluxo de Autenticação OIDC

1. Usuário acessa `https://argo.stackfood.com.br`
2. ArgoCD redireciona para Cognito
3. Usuário faz login com credenciais Cognito
4. Cognito retorna token com grupos
5. ArgoCD autoriza baseado nos grupos

## 🌐 Registros DNS Criados

### Automáticos

- `argo.stackfood.com.br` → Load Balancer do NGINX Ingress

### Configuráveis

Use a variável `dns_records` para criar registros adicionais:

```hcl
dns_records = {
  "api" = {
    name    = "api"
    type    = "CNAME"
    content = "api-gateway.amazonaws.com"
  }
}
```

## 📋 Checklist de Implementação

- [ ] **Pré-requisitos**
  - [ ] EKS cluster funcionando
  - [ ] NGINX Ingress instalado
  - [ ] Cloudflare API configurada
  
- [ ] **Terraform**
  - [ ] Variáveis configuradas
  - [ ] Providers adicionados
  - [ ] Módulos copiados
  
- [ ] **Deploy**
  - [ ] `terraform init`
  - [ ] `terraform plan`
  - [ ] `terraform apply`
  
- [ ] **Validação**
  - [ ] DNS resolvendo
  - [ ] ArgoCD acessível
  - [ ] Login Cognito funcionando

## 🚨 Comandos Úteis

### Verificar instalação ArgoCD

```bash
# Ver pods do ArgoCD
kubectl get pods -n argocd

# Ver serviços
kubectl get svc -n argocd

# Ver ingress
kubectl get ingress -n argocd
```

### Obter senha admin padrão

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode
```

### Verificar registros DNS

```bash
# Verificar resolução DNS
nslookup argo.stackfood.com.br

# Testar HTTPS
curl -I https://argo.stackfood.com.br
```

## 🔧 Troubleshooting

### ArgoCD não carrega

1. Verificar se NGINX Ingress está rodando
2. Verificar certificado SSL
3. Verificar logs do ArgoCD server

### Autenticação Cognito falhando

1. Verificar callback URLs no Cognito
2. Verificar client secret
3. Verificar configuração OIDC no ArgoCD

### DNS não resolvendo

1. Verificar zona Cloudflare
2. Verificar API token Cloudflare
3. Verificar TTL e propagação

## 📞 Suporte

Em caso de problemas:

1. Verificar logs do Terraform
2. Verificar logs dos pods Kubernetes
3. Verificar configuração dos providers
4. Consultar documentação oficial do ArgoCD

## 🔗 Links Úteis

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [AWS Cognito OIDC](https://docs.aws.amazon.com/cognito/latest/developerguide/open-id.html)
- [Cloudflare API](https://developers.cloudflare.com/api/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

---

**Implementação baseada no tutorial:** [Installing ArgoCD and Securing Access Using Amazon Cognito](https://medium.com/@rvisingh1221/installing-argocd-and-securing-access-using-amazon-cognito-6f6cb7a8f2f5)