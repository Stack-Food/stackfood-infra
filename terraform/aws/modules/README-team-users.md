# Configuração de Usuários da Equipe ArgoCD

## Visão Geral

Este documento explica como configurar os usuários da equipe para o ArgoCD usando configuração externa via arquivo `prod.tfvars`.

## Configuração no arquivo prod.tfvars

Os usuários da equipe do ArgoCD devem ser configurados no arquivo `env/prod.tfvars`:

```hcl
# Configuração dos usuários da equipe do ArgoCD
argocd_team_users = {
  "leonardo.duarte" = {
    name  = "Leonardo Duarte"
    email = "leo.duarte.dev@gmail.com"
  }
  "luiz.felipe" = {
    name  = "Luiz Felipe Maia"
    email = "luiz.felipeam@hotmail.com"
  }
  "leonardo.lemos" = {
    name  = "Leonardo Luiz Lemos"
    email = "leoo_lemos@outlook.com"
  }
  "rodrigo.silva" = {
    name  = "Rodrigo Rodriguez Figueiredo de Oliveira Silva"
    email = "rodrigorfig1@gmail.com"
  }
  "vinicius.targa" = {
    name  = "Vinicius Targa Gonçalves"
    email = "viniciustarga@gmail.com"
  }
}

# Senha padrão para todos os usuários da equipe
argocd_team_password = "StackFood@2025"

# Usuario principal do StackFood
argocd_stackfood_username = "stackfood"
argocd_stackfood_password = "Fiap@2025"
```

## Estrutura dos Usuários

Cada usuário deve seguir a estrutura:

```hcl
"username" = {
  name  = "Nome Completo"
  email = "email@exemplo.com"
}
```

Onde:

- `username`: Nome de usuário único (usado para login)
- `name`: Nome completo do usuário
- `email`: E-mail para notificações e convites

## Funcionalidades

### Criação Automática

- Todos os usuários são criados automaticamente no User Pool do ArgoCD
- Emails de convite são enviados para cada usuário
- Usuários são adicionados ao grupo `argocd-admin` automaticamente

### Segurança

- Senhas são marcadas como temporárias
- Usuários devem alterar a senha no primeiro login
- Emails são validados automaticamente

### Acesso

- URL de acesso: `https://argo.stackfood.com.br`
- Autenticação via AWS Cognito OIDC
- Permissões administrativas completas no ArgoCD

## Vantagens da Configuração Externa

1. **Separação de Responsabilidades**: Configuração de usuários separada do código de infraestrutura
2. **Flexibilidade**: Fácil adição/remoção de usuários sem alterar módulos
3. **Ambiente-Específico**: Diferentes usuários para diferentes ambientes
4. **Segurança**: Senhas e informações sensíveis centralizadas em arquivos de configuração
5. **Manutenibilidade**: Atualizações de equipe sem alterações de código

## Comandos para Deploy

```bash
# Navegar para o diretório principal
cd terraform/aws/main

# Verificar mudanças
terraform plan -var-file="../env/prod.tfvars"

# Aplicar configurações
terraform apply -var-file="../env/prod.tfvars"
```

## Outputs Disponíveis

Após o deploy, você pode verificar os usuários criados:

```bash
terraform output argocd_team_users_created
```

## Solução de Problemas

### Usuários não criados

- Verifique se `create_team_users = true` no tfvars
- Confirme que o mapa `argocd_team_users` está preenchido
- Verifique os logs do Terraform para erros de criação

### Emails não enviados

- Confirme que os endereços de email estão corretos
- Verifique se o domínio do Cognito está verificado
- Confirme que o SES está configurado (se necessário)

### Problemas de acesso

- Verifique se o DNS está resolvendo corretamente
- Confirme que o Load Balancer está funcionando
- Teste a configuração OIDC no ArgoCD

## Exemplo de Adição de Novo Usuário

Para adicionar um novo usuário, simplesmente adicione uma entrada ao mapa em `prod.tfvars`:

```hcl
argocd_team_users = {
  # ... usuários existentes ...
  "novo.usuario" = {
    name  = "Novo Usuario"
    email = "novo.usuario@empresa.com"
  }
}
```

Depois execute:

```bash
terraform plan -var-file="../env/prod.tfvars"
terraform apply -var-file="../env/prod.tfvars"
```
