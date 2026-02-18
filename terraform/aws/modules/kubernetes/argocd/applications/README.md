# Applications do ArgoCD

Esta pasta contém as definições das Applications do ArgoCD. Cada arquivo YAML nesta pasta representa uma Application que será automaticamente criada pelo Terraform.

## 🚀 Como Adicionar um Novo Microserviço

### 1. Copie o template

```bash
cp application-template.yaml seu-servico.yaml
```

### 2. Edite o arquivo

Substitua os valores entre `<>`:

```yaml
metadata:
  name: payment # Nome da application

spec:
  source:
    path: apps/payment/prod # Caminho dos manifestos

  destination:
    namespace: payment # Namespace no Kubernetes
```

### 3. Aplique com Terraform

```bash
cd terraform/aws/main
terraform apply -var-file=../env/prod.tfvars
```

Pronto! A Application será criada no ArgoCD automaticamente.

## 📋 Exemplos Incluídos

- `api.yaml` - Application para o serviço API
- `worker.yaml` - Application para o serviço Worker
- `application-template.yaml` - Template base para copiar

## 🔧 Estrutura do YAML

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <nome> # Nome único da application
  namespace: argocd # Sempre argocd
  labels:
    app: <nome>
    team: OptimusFrame

spec:
  project: default # Projeto do ArgoCD

  source:
    repoURL: <git-url> # URL do repositório Git
    targetRevision: main # Branch, tag ou commit
    path: <path> # Caminho dos manifestos no repo

  destination:
    server: https://kubernetes.default.svc # Cluster
    namespace: <namespace> # Namespace de destino

  syncPolicy:
    automated:
      prune: true # Remove recursos deletados
      selfHeal: true # Corrige drifts automaticamente
```

## ✅ Verificar Applications

```bash
# Listar applications
kubectl get applications -n argocd

# Ver detalhes
kubectl describe application api -n argocd

# Ver status via ArgoCD CLI
argocd app list
argocd app get api
```

## 🗑️ Remover Application

Para remover uma Application, simplesmente delete o arquivo YAML e aplique o Terraform novamente:

```bash
rm applications/payment.yaml
terraform apply -var-file=../env/prod.tfvars
```

## 📝 Boas Práticas

1. **Nomenclatura:** Use nomes descritivos e em lowercase
2. **Labels:** Adicione labels para organização (`team`, `environment`, `tier`)
3. **Namespace:** Use um namespace dedicado por microserviço
4. **Sync Policy:** Use `automated` para CI/CD completo
5. **Finalizers:** Sempre inclua `resources-finalizer.argocd.argoproj.io`

## 🔗 Estrutura Esperada no Git

Para cada Application, certifique-se de que existe a estrutura:

```
apps/
└── seu-servico/
    └── prod/
        ├── kustomization.yaml  # Obrigatório
        ├── deployment.yaml
        ├── service.yaml
        └── ... (outros manifestos)
```

O ArgoCD vai buscar os manifestos no caminho especificado em `spec.source.path`.
