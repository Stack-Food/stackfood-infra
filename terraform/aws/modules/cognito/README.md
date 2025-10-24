# Módulo Cognito Unificado

Este módulo cria um User Pool do Amazon Cognito unificado para autenticação tanto da aplicação principal StackFood quanto de ferramentas de gerenciamento como ArgoCD e Grafana.

## Arquitetura

### User Pool Único

- **Nome**: stackfood
- **Finalidade**: Autenticação unificada para aplicação e ferramentas de gerenciamento
- **Configuração**: Suporte a grupos para controle de acesso granular

### Grupos Criados

1. **app-users** (precedência 10)

   - Usuários regulares da aplicação StackFood
   - Acesso apenas à aplicação principal

2. **app-admins** (precedência 5)

   - Administradores da aplicação StackFood
   - Acesso administrativo à aplicação principal

3. **argocd** (precedência 3)

   - Usuários com acesso ao ArgoCD
   - Controle de deployment e GitOps

4. **grafana** (precedência 4)

   - Usuários com acesso ao Grafana
   - Monitoramento e observabilidade

5. **system-admins** (precedência 1)
   - Administradores de sistema
   - Acesso total a todas as ferramentas

### Integração com ArgoCD

O ArgoCD está configurado para usar grupos do Cognito:

```yaml
rbac:
  policy.csv: |
    # Grupos do Cognito mapeados para roles
    g, argocd, role:admin
    g, system-admins, role:admin
  scopes: "[cognito:groups]"

oidc.config: |
  requestedIDTokenClaims: {"cognito:groups": {"essential": true}}
  groupsClaim: "cognito:groups"
```

## Como Aplicar as Mudanças

Para aplicar esta nova estrutura unificada do Cognito:

```bash
cd /home/luizf/fiap/stackfood-infra/terraform/aws/main

# 1. Validar as mudanças
terraform plan -target=module.cognito -target=module.argocd -var-file=../env/prod.tfvars

# 2. Aplicar as mudanças
terraform apply -target=module.cognito -target=module.argocd -var-file=../env/prod.tfvars
```

## Benefícios da Nova Estrutura

1. **Gestão Simplificada**: Um único User Pool para todas as aplicações
2. **Controle Granular**: Grupos permitem acesso específico por ferramenta
3. **Escalabilidade**: Fácil adição de novas ferramentas e usuários
4. **Segurança**: Autenticação OIDC padronizada com grupos
5. **Manutenção**: Redução de recursos duplicados
