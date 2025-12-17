# 🚀 Módulo ArgoCD - GitOps com Cognito

## 📖 Visão Geral

Este módulo implanta o **ArgoCD** no Kubernetes (EKS) com:

- ✅ **Autenticação Cognito (OIDC)** - Login via AWS Cognito com SSO
- ✅ **Applications automatizadas** - Crie Applications através de arquivos YAML
- ✅ **DNS Cloudflare** - Registros DNS automatizados
- ✅ **RBAC** - Controle de acesso por grupos
- ✅ **GitOps** - Sincronização automática com Git

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   AWS Cognito   │    │      EKS        │
│   DNS Records   │◄──►│   User Pool     │◄──►│   ArgoCD        │
│   argo.domain   │    │   OIDC Client   │    │   Applications  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ✨ Como Funciona - Applications Automatizadas

Basta adicionar um arquivo YAML na pasta `applications/` e executar `terraform apply`. O Terraform criará automaticamente a Application no ArgoCD.

```
applications/payment.yaml → terraform apply → Application criada → Microserviço implantado
```

## 🎯 Quick Start

### 1. Adicionar novo microserviço

```bash
# Copiar template
cd applications/
cp application-template.yaml payment.yaml

# Editar valores
# - metadata.name: payment
# - spec.source.path: apps/payment/prod
# - spec.destination.namespace: payment
```

### 2. Aplicar Terraform

```bash
cd terraform/aws/main
terraform apply -var-file=../env/prod.tfvars
```

### 3. Verificar

```bash
kubectl get applications -n argocd
argocd app get payment
```

## 📁 Estrutura

```
terraform/aws/modules/kubernetes/argocd/
├── applications/              # ← Adicione seus YAMLs aqui
│   ├── README.md             # Documentação da pasta
│   ├── application-template.yaml  # Template para copiar
│   ├── api.yaml              # Application da API
│   └── worker.yaml           # Application do Worker
├── main.tf                   # Aplica os YAMLs automaticamente
├── variables.tf
└── argocd.yaml              # Configuração do ArgoCD
```

## 📝 Exemplo de Application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payment
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/Stack-Food/stackfood-infra.git
    targetRevision: main
    path: apps/payment/prod # Caminho dos manifestos

  destination:
    server: https://kubernetes.default.svc
    namespace: payment

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 🔧 Recursos Criados

- ✅ ArgoCD Server com UI Web
- ✅ Autenticação via Cognito (SSO)
- ✅ RBAC com grupos de admin e readonly
- ✅ Ingress com SSL
- ✅ Applications automáticas da pasta `applications/`

## ⚙️ Variáveis

| Variável                    | Descrição                         | Padrão            |
| --------------------------- | --------------------------------- | ----------------- |
| `domain_name`               | Domínio base                      | obrigatório       |
| `argocd_subdomain`          | Subdomínio do ArgoCD              | "argo"            |
| `cognito_user_pool_id`      | ID do User Pool Cognito           | obrigatório       |
| `cognito_client_id`         | Client ID do Cognito              | obrigatório       |
| `cognito_client_secret`     | Client Secret do Cognito          | obrigatório       |
| `cognito_region`            | Região AWS do Cognito             | obrigatório       |
| `cognito_client_issuer_url` | URL do issuer OIDC                | obrigatório       |
| `user_pool_name`            | Nome base do User Pool            | obrigatório       |
| `certificate_arn`           | ARN do certificado ACM            | obrigatório       |
| `chart_version`             | Versão do Helm chart do ArgoCD    | "5.51.0"          |
| `namespace`                 | Namespace do Kubernetes           | "argocd"          |
| `admin_group_name`          | Nome do grupo admin no Cognito    | "argocd-admin"    |
| `readonly_group_name`       | Nome do grupo readonly no Cognito | "argocd-readonly" |

## 📤 Outputs

| Output                   | Descrição                      |
| ------------------------ | ------------------------------ |
| `argocd_url`             | URL do ArgoCD                  |
| `argocd_namespace`       | Namespace do Kubernetes        |
| `argocd_release_name`    | Nome do Helm release           |
| `admin_password_command` | Comando para obter senha admin |

## 💻 Uso

```hcl
module "argocd" {
  source = "../modules/kubernetes/argocd/"

  domain_name      = "stackfood.com.br"
  argocd_subdomain = "argo"

  cognito_user_pool_id      = module.cognito.argocd_user_pool_id
  cognito_client_id         = module.cognito.argocd_client_id
  cognito_client_secret     = module.cognito.argocd_client_secret
  cognito_region            = "us-east-1"
  cognito_client_issuer_url = module.cognito.argocd_issuer_url
  user_pool_name            = "stackfood"

  certificate_arn = module.acm.certificate_arn
}
```

## ✅ Verificação

```bash
# Listar applications
kubectl get applications -n argocd

# Ver detalhes
kubectl describe application api -n argocd

# Acessar UI
# https://argo.stackfood.com.br

# Obter senha inicial do admin
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

## 🗑️ Remover Application

Para remover uma Application, delete o arquivo YAML correspondente e aplique o Terraform:

```bash
rm applications/payment.yaml
terraform apply -var-file=../env/prod.tfvars
```

---

## 🔐 Autenticação Cognito

### Usuários Criados Automaticamente

O módulo Cognito cria automaticamente os seguintes usuários:

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
4. Cognito retorna token com grupos (`cognito:groups`)
5. ArgoCD autoriza baseado nos grupos

### Grupos e Permissões

- **argocd-admin**: Acesso total (criar, editar, deletar applications)
- **argocd-readonly**: Acesso apenas leitura (visualizar applications)

---

## 🌐 DNS e Cloudflare

### Registros DNS Criados

O módulo DNS cria automaticamente:

- `argo.stackfood.com.br` → Load Balancer do NGINX Ingress

### Configurar DNS Manualmente

Se preferir criar registros DNS adicionais:

```hcl
module "dns_argocd" {
  source = "../modules/dns-cloudflare/"

  cloudflare_zone_id     = var.cloudflare_zone_id
  domain_name            = var.domain_name
  load_balancer_dns_name = module.nginx_ingress.load_balancer_dns

  argocd_subdomain = "argo"
  proxied          = false
  ttl              = 300
}
```

---

## 📋 Pré-requisitos

Antes de aplicar este módulo, certifique-se de ter:

- ✅ Cluster EKS funcionando
- ✅ NGINX Ingress Controller instalado
- ✅ Cognito User Pool configurado com grupos
- ✅ Certificado ACM para o domínio
- ✅ Cloudflare configurado (opcional)
- ✅ Terraform >= 1.0

---

## 🚨 Comandos Úteis

### Verificar Instalação

```bash
# Ver pods do ArgoCD
kubectl get pods -n argocd

# Ver serviços
kubectl get svc -n argocd

# Ver ingress
kubectl get ingress -n argocd

# Ver applications
kubectl get applications -n argocd
```

### Obter Senha Admin

```bash
# Senha inicial do admin
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
```

### Verificar DNS

```bash
# Verificar resolução DNS
nslookup argo.stackfood.com.br

# Testar HTTPS
curl -I https://argo.stackfood.com.br
```

### ArgoCD CLI

```bash
# Login
argocd login argo.stackfood.com.br

# Listar applications
argocd app list

# Ver detalhes
argocd app get payment

# Sincronizar
argocd app sync payment

# Ver histórico
argocd app history payment

# Rollback
argocd app rollback payment <revision>
```

---

## 🔧 Troubleshooting

### ArgoCD não carrega

```bash
# 1. Verificar NGINX Ingress
kubectl get pods -n ingress-nginx

# 2. Verificar certificado SSL
kubectl get certificate -n argocd

# 3. Ver logs do ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

### Autenticação Cognito falhando

1. Verificar callback URLs no Cognito:
   - `https://argo.stackfood.com.br/auth/callback`
2. Verificar client secret:

   ```bash
   # Deve estar configurado no argocd-secret
   kubectl get secret argocd-secret -n argocd -o yaml
   ```

3. Verificar configuração OIDC:
   ```bash
   kubectl get configmap argocd-cm -n argocd -o yaml
   ```

### Application não sincroniza

```bash
# Ver eventos
kubectl describe application payment -n argocd

# Ver diff
argocd app diff payment

# Forçar sync
argocd app sync payment --force
```

### DNS não resolvendo

1. Verificar zona Cloudflare
2. Verificar API token Cloudflare
3. Aguardar propagação (pode levar alguns minutos)
4. Verificar registros:
   ```bash
   dig argo.stackfood.com.br
   ```

---

## 📦 Funcionalidades

### Application Management

- Sincronização automática com Git
- Suporte a Helm charts
- Suporte a Kustomize
- Políticas de sync configuráveis
- Rollback automático

### Monitoring e Observability

- Dashboard de saúde das applications
- Monitoramento de sync status
- Detecção de drift
- Métricas de performance
- Logs centralizados

### Security

- RBAC com permissões granulares
- Autenticação OIDC via Cognito
- TLS/SSL em todas as comunicações
- Integração com Sealed Secrets
- Network policies

---

## 📚 Documentação Adicional

- [Criar Applications](applications/README.md) - Guia detalhado da pasta applications/
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [AWS Cognito OIDC](https://docs.aws.amazon.com/cognito/latest/developerguide/open-id.html)
- [Cloudflare API](https://developers.cloudflare.com/api/)

---

**💡 Dica:** Veja exemplos prontos em [applications/api.yaml](applications/api.yaml) e [applications/worker.yaml](applications/worker.yaml)
