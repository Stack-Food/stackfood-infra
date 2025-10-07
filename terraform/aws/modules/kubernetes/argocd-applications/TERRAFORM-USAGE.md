# 🚀 Como Usar o Módulo ArgoCD Applications

## 📋 Visão Geral

O módulo `argocd-applications` automatiza a criação de aplicações ArgoCD usando Terraform, eliminando a necessidade de aplicar YAMLs manualmente.

## 🎯 Configuração Atual

### Estrutura Esperada no Repository stackfood-api

```
stackfood-api/
├── manifests/
│   ├── namespaces/
│   │   └── namespace.yaml           # Namespace stackfood-prod
│   ├── api/
│   │   ├── base/                    # Kustomize base
│   │   │   ├── kustomization.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── ingress.yaml
│   │   └── prod/                    # Production overlay
│   │       ├── kustomization.yaml
│   │       ├── configmap.yaml
│   │       ├── secret.yaml
│   │       └── patch-deployment.yaml
│   └── worker/                      # Worker applications
│       ├── base/
│       └── prod/
└── src/                             # Application source code
```

## ⚙️ Deploy via Terraform

### 1. Aplicar a Infraestrutura

```bash
cd terraform/aws/main
terraform plan -var-file="../env/prod.tfvars"
terraform apply -var-file="../env/prod.tfvars"
```

### 2. Verificar Criação das Aplicações

```bash
# Verificar aplicações criadas
kubectl get applications -n argocd

# Verificar projeto
kubectl get appproject stackfood -n argocd

# Status detalhado
kubectl describe application stackfood-api -n argocd
```

## 🔧 Configuração do Módulo

O módulo está configurado no `main.tf` com:

```hcl
module "argocd_applications" {
  source = "../modules/kubernetes/argocd-applications"

  # Repository da aplicação
  source_repo_url = "https://github.com/Stack-Food/stackfood-api.git"
  target_revision = "master"               # Branch master

  # Namespace de destino
  api_namespace    = "stackfood-prod"
  worker_namespace = "stackfood-prod"

  # Política de sync (conservadora para produção)
  enable_auto_sync = false                 # Sync manual
  enable_self_heal = true                  # Auto-correção
  enable_prune     = true                  # Limpeza automática
}
```

## 🔄 Fluxo de Deploy

### Automático via Terraform

1. **Infrastructure**: Terraform cria projeto e aplicações ArgoCD
2. **Detection**: ArgoCD detecta repositório stackfood-api
3. **Manual Sync**: Operador inicia sync manual (produção)
4. **Deployment**: ArgoCD faz deploy dos manifestos

### Sync Manual (Recomendado para Produção)

```bash
# Via ArgoCD CLI
argocd app sync stackfood-api

# Via kubectl
kubectl patch application stackfood-api -n argocd \
  --type merge -p '{"operation":{"sync":{"revision":"HEAD"}}}'
```

## 🎛️ Personalização

### Habilitar Auto Sync (Desenvolvimento)

```hcl
module "argocd_applications" {
  # ... outras configurações
  enable_auto_sync = true  # Para desenvolvimento
}
```

### Diferentes Branches

```hcl
module "argocd_applications_dev" {
  source = "../modules/kubernetes/argocd-applications"

  target_revision  = "develop"        # Branch develop
  api_namespace    = "stackfood-dev"
  enable_auto_sync = true             # Auto sync para dev
}
```

## 📊 Outputs Disponíveis

Após o `terraform apply`, você terá acesso a:

```hcl
output "argocd_applications_info" {
  value = {
    project_name      = "stackfood"
    source_repository = "https://github.com/Stack-Food/stackfood-api.git"
    target_revision   = "master"
    applications = {
      api = { name = "stackfood-api", namespace = "argocd" }
      worker = { name = "stackfood-worker", namespace = "argocd" }
      namespaces = { name = "stackfood-namespaces", namespace = "argocd" }
    }
  }
}
```

## 🔍 Troubleshooting

### Aplicação Não Sincroniza

```bash
# Verificar status
kubectl get application stackfood-api -n argocd -o yaml

# Forçar refresh
kubectl annotate application stackfood-api -n argocd \
  argocd.argoproj.io/refresh=hard
```

### Problemas de Acesso ao Repository

```bash
# Verificar configuração do projeto
kubectl get appproject stackfood -n argocd -o yaml

# Verificar repositórios configurados
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
```

### Logs do ArgoCD

```bash
# Logs do controller
kubectl logs -n argocd deployment/argocd-application-controller

# Logs do server
kubectl logs -n argocd deployment/argocd-server
```

## 🚀 Próximos Passos

1. **Configurar Repository**: Criar estrutura de manifests no stackfood-api
2. **Testar Sync**: Fazer primeiro deploy manual
3. **Configurar CI/CD**: Automatizar build e update de images
4. **Monitoramento**: Configurar alertas para falhas de sync

---

## 📝 Vantagens do Terraform vs YAML

### ✅ Com Terraform

- **Versionamento**: Configuração versionada junto com infraestrutura
- **State Management**: Estado centralizado e consistente
- **Dependencies**: Dependências automáticas entre recursos
- **Variables**: Configuração parametrizada e reutilizável
- **Validation**: Validação durante o plan
- **Rollback**: Rollback automático em caso de falha

### ❌ YAML Manual

- Aplicação manual prone a erros
- Sem gerenciamento de estado
- Dependências manuais
- Configuração hardcoded
- Sem validação prévia
- Rollback manual

---

**💡 Dica**: Use o Terraform para configurar a infraestrutura do GitOps e deixe o ArgoCD gerenciar os deployments das aplicações!
