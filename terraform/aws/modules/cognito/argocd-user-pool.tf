
###########################
# ArgoCD User Pool        #
###########################

resource "aws_cognito_user_pool" "argocd" {
  name = "${var.user_pool_name}-argocd"

  # Sign-in options: username only (sem alias_attributes)
  
  # Política de senha padrão do Cognito (sem especificar para usar default)
  
  # Configurações de verificação e recuperação
  auto_verified_attributes = ["email"]
  
  # Account recovery settings - email only
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Configuração de email
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Admin create user config - self registration disabled
  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      email_message = "Olá {username}! Bem-vindo ao ArgoCD StackFood! 🚀\n\nSua conta foi criada com sucesso. Use as credenciais abaixo para acessar:\n\nURL: https://argo.stackfood.com.br\nUsername: {username}\nSenha temporária: {####}\n\nVocê será solicitado a alterar sua senha no primeiro login.\n\nEquipe StackFood"
      email_subject = "🚀 Acesso ao ArgoCD StackFood - Bem-vindo à equipe!"
      sms_message   = "StackFood ArgoCD - Username: {username}, Senha temporária: {####}"
    }
  }

  tags = {
    Name        = "${var.user_pool_name}-argocd"
    Environment = var.environment
    Service     = "ArgoCD"
    Purpose     = "OIDC Authentication"
  }
}

# ArgoCD User Pool Domain
resource "aws_cognito_user_pool_domain" "argocd" {
  domain       = "${var.user_pool_name}-argocd"
  user_pool_id = aws_cognito_user_pool.argocd.id
}

###########################
# ArgoCD Groups           #
###########################

# ArgoCD Admin Group
resource "aws_cognito_user_group" "argocd_admin" {
  name         = "argocd-admin"
  user_pool_id = aws_cognito_user_pool.argocd.id
  description  = "ArgoCD Administrator Group"
  precedence   = 1
}

###########################
# StackFood Admin User    #
###########################

resource "aws_cognito_user" "stackfood_admin" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = "stackfood"
  password     = var.stackfood_admin_password

  # Suprime o e-mail de boas-vindas, criando usuário confirmado
  message_action = "SUPPRESS"

  attributes = {
    name           = "StackFood Administrator"
    email          = "admin@stackfood.com.br"
    email_verified = true
  }
}

# Add StackFood user to ArgoCD admin group
resource "aws_cognito_user_in_group" "stackfood_admin_group" {
  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.argocd_admin.name
}

###########################
# Team Users for ArgoCD   #
###########################

# Criar usuários da equipe
resource "aws_cognito_user" "team_users" {
  for_each = var.argocd_team_users

  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = each.key
  password     = var.argocd_team_password

  # Força a criação de usuários permanentes (sem e-mail de convite inicial)
  message_action = "SUPPRESS"

  attributes = {
    name           = each.value.name
    email          = each.value.email
    email_verified = true # Marcado como verificado para evitar problemas de criação
  }

  # Garantir que o user pool seja criado antes dos usuários
  depends_on = [aws_cognito_user_pool.argocd]
}

# Adicionar usuários da equipe ao grupo admin
resource "aws_cognito_user_in_group" "team_users_admin_group" {
  for_each = var.argocd_team_users

  user_pool_id = aws_cognito_user_pool.argocd.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.argocd_admin.name

  # Garantir que os usuários e grupos sejam criados antes da associação
  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.argocd_admin
  ]
}

###########################
# App Client for ArgoCD   #
###########################

resource "aws_cognito_user_pool_client" "argocd" {
  name         = "${var.user_pool_name}-argocd-client"
  user_pool_id = aws_cognito_user_pool.argocd.id

  # Generate secret for OIDC integration
  generate_secret = true

  # Token validity
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # OAuth flows for OIDC
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "phone"]

  # Callback URLs for ArgoCD
  callback_urls = var.argocd_callback_urls
  logout_urls   = var.argocd_logout_urls

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Attributes
  read_attributes  = ["email", "email_verified", "name", "phone_number"]
  write_attributes = ["email", "name", "phone_number"]
}
