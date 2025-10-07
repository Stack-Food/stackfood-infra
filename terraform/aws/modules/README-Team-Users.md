# 👥 Usuários da Equipe StackFood - ArgoCD

## 🎯 **Usuários Criados Automaticamente**

O módulo Cognito foi configurado para criar automaticamente os seguintes usuários da equipe StackFood no User Pool do ArgoCD:

### **👨‍💻 Usuários da Equipe**

| Username          | Nome Completo                                  | Email                     | Grupo        |
| ----------------- | ---------------------------------------------- | ------------------------- | ------------ |
| `leonardo.duarte` | Leonardo Duarte                                | leo.duarte.dev@gmail.com  | argocd-admin |
| `luiz.felipe`     | Luiz Felipe Maia                               | luiz.felipeam@hotmail.com | argocd-admin |
| `leonardo.lemos`  | Leonardo Luiz Lemos                            | leoo_lemos@outlook.com    | argocd-admin |
| `rodrigo.silva`   | Rodrigo Rodriguez Figueiredo de Oliveira Silva | rodrigorfig1@gmail.com    | argocd-admin |
| `vinicius.targa`  | Vinicius Targa Gonçalves                       | viniciustarga@gmail.com   | argocd-admin |

### **🔐 Credenciais Padrão**

- **Senha inicial**: `StackFood@2025`
- **Acesso**: https://argo.stackfood.com.br
- **Permissões**: Administrador completo do ArgoCD
- **Primeira vez**: Usuários serão obrigados a alterar a senha no primeiro login

## 📧 **Emails Automatizados**

Cada usuário receberá automaticamente um email de boas-vindas com:

```
🚀 Acesso ao ArgoCD StackFood - Bem-vindo à equipe!

Olá {username}! Bem-vindo ao ArgoCD StackFood! 🚀

Sua conta foi criada com sucesso. Use as credenciais abaixo para acessar:

URL: https://argo.stackfood.com.br
Username: {username}
Senha temporária: StackFood@2025

Você será solicitado a alterar sua senha no primeiro login.

Equipe StackFood
```

## ⚙️ **Configuração do Módulo**

Para habilitar a criação dos usuários da equipe:

```hcl
module "cognito" {
  source = "../modules/cognito/"

  user_pool_name = "stackfood"
  environment    = "prod"

  # Habilitar criação dos usuários da equipe
  create_team_users = true
  team_users_password = "StackFood@2025"

  # Outras configurações...
  create_argocd_user_pool = true
  stackfood_admin_password = "Fiap@2025"
}
```

## 🎮 **Controle de Criação**

### **Criar usuários da equipe (padrão)**

```hcl
create_team_users = true
```

### **Não criar usuários da equipe**

```hcl
create_team_users = false
```

### **Personalizar senha**

```hcl
team_users_password = "MinhaSenarCustomizada123!"
```

## 📊 **Verificar Usuários Criados**

### **Via Terraform Output**

```bash
terraform output team_users_info
```

### **Via AWS CLI**

```bash
# Listar todos os usuários do User Pool ArgoCD
aws cognito-idp list-users --user-pool-id <argocd-user-pool-id>

# Ver detalhes de um usuário específico
aws cognito-idp admin-get-user --user-pool-id <pool-id> --username leonardo.duarte
```

### **Via Console AWS**

1. Acesse o **AWS Cognito Console**
2. Selecione o User Pool **stackfood-argocd**
3. Navegue para **Users** para ver todos os usuários

## 🔧 **Gerenciamento de Usuários**

### **Redefinir senha via AWS CLI**

```bash
aws cognito-idp admin-set-user-password \
  --user-pool-id <pool-id> \
  --username leonardo.duarte \
  --password "NovaSenha123!" \
  --permanent
```

### **Reenviar email de convite**

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <pool-id> \
  --username leonardo.duarte \
  --message-action RESEND
```

### **Remover usuário**

```bash
aws cognito-idp admin-delete-user \
  --user-pool-id <pool-id> \
  --username leonardo.duarte
```

## 🚀 **Processo de Login**

1. **Primeiro acesso**: https://argo.stackfood.com.br
2. **Clicar em**: "Login via Cognito" ou botão SSO
3. **Inserir credenciais**:
   - Username: `leonardo.duarte` (exemplo)
   - Password: `StackFood@2025`
4. **Alterar senha**: Sistema solicitará nova senha
5. **Acessar ArgoCD**: Interface completa com permissões admin

## 🛡️ **Segurança e Melhores Práticas**

### ✅ **Implementado**

- Senha inicial forte (`StackFood@2025`)
- Obrigatório alterar senha no primeiro login
- Emails individuais para cada usuário
- Grupo admin com permissões completas
- Usernames únicos e identificáveis

### 🔒 **Recomendações**

- Alterar senhas regularmente
- Habilitar MFA (pode ser configurado posteriormente)
- Monitorar logs de acesso
- Revisar permissões periodicamente

## 📝 **Logs e Monitoramento**

### **CloudTrail Events**

- `CreateUser` - Criação de usuários
- `AdminCreateUser` - Criação via admin
- `InitiateAuth` - Tentativas de login

### **Cognito Logs**

- User creation events
- Authentication attempts
- Password changes

## 🆘 **Troubleshooting**

### **Usuário não recebeu email**

1. Verificar se email está correto no Terraform
2. Checar pasta de spam
3. Reenviar convite via AWS CLI
4. Verificar configuração de email no Cognito

### **Erro no primeiro login**

1. Confirmar username exato (ex: `leonardo.duarte`)
2. Usar senha inicial: `StackFood@2025`
3. Verificar URL: https://argo.stackfood.com.br
4. Limpar cache do navegador

### **Não consegue alterar senha**

1. Verificar política de senha do User Pool
2. Nova senha deve ser diferente da anterior
3. Seguir requisitos: maiúscula, minúscula, número

---

**🎯 RESUMO**: Todos os usuários da equipe são criados automaticamente com acesso admin ao ArgoCD, senha inicial `StackFood@2025` e recebem email de boas-vindas com instruções completas.
