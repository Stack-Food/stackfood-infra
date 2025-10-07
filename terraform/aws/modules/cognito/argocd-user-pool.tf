
###########################
# ArgoCD Dedicated User Pool #
###########################

resource "aws_cognito_user_pool" "argocd" {
  count = var.create_argocd_user_pool ? 1 : 0

  name = "${var.user_pool_name}-argocd"

  # Configuração específica para ArgoCD
  alias_attributes = ["email", "preferred_username"]

  # Política de senha para ArgoCD
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Schema para ArgoCD
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Configurações de verificação
  auto_verified_attributes = ["email"]

  # Configuração de email
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false

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
  count = var.create_argocd_user_pool ? 1 : 0

  domain       = "${var.user_pool_name}-argocd"
  user_pool_id = aws_cognito_user_pool.argocd[0].id
}

###########################
# ArgoCD User & Groups    #
###########################

# ArgoCD Admin Group
resource "aws_cognito_user_group" "argocd_admin" {
  count = var.create_argocd_user_pool ? 1 : 0

  name         = "argocd-admin"
  user_pool_id = aws_cognito_user_pool.argocd[0].id
  description  = "ArgoCD Administrator Group"
  precedence   = 1
}

# ArgoCD Readonly Group
resource "aws_cognito_user_group" "argocd_readonly" {
  count = var.create_argocd_user_pool ? 1 : 0

  name         = "argocd-readonly"
  user_pool_id = aws_cognito_user_pool.argocd[0].id
  description  = "ArgoCD Read-only Group"
  precedence   = 2
}

# StackFood Admin User
resource "aws_cognito_user" "stackfood_admin" {
  count = var.create_argocd_user_pool ? 1 : 0

  user_pool_id = aws_cognito_user_pool.argocd[0].id
  username     = "stackfood"
  password     = var.stackfood_admin_password

  # Suprime o e-mail de boas-vindas, o que, em conjunto com a definição da senha,
  # cria o usuário com o status CONFIRMED, tornando a senha "permanente"
  # e não exigindo alteração no primeiro login.
  message_action = "SUPPRESS"

  attributes = {
    name           = "StackFood Administrator"
    email          = "admin@stackfood.com.br"
    email_verified = true
  }
}

# Add StackFood user to ArgoCD admin group
resource "aws_cognito_user_in_group" "stackfood_admin_group" {
  count = var.create_argocd_user_pool ? 1 : 0

  user_pool_id = aws_cognito_user_pool.argocd[0].id
  username     = aws_cognito_user.stackfood_admin[0].username
  group_name   = aws_cognito_user_group.argocd_admin[0].name
}

###########################
# Team Users for ArgoCD   #
###########################

# Criar usuários da equipe
resource "aws_cognito_user" "team_users" {
  for_each = local.team_users

  user_pool_id = aws_cognito_user_pool.argocd[0].id
  username     = each.key
  password     = var.argocd_team_password

  # Força o usuário a alterar a senha no primeiro login
  message_action = "RESEND"

  attributes = {
    name           = each.value.name
    email          = each.value.email
    email_verified = false # Será verificado quando o usuário acessar o email
  }

  # Aguarda a criação do User Pool
  depends_on = [aws_cognito_user_pool.argocd]
}

# Adicionar usuários da equipe ao grupo admin
resource "aws_cognito_user_in_group" "team_users_admin_group" {
  for_each = local.team_users

  user_pool_id = aws_cognito_user_pool.argocd[0].id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.argocd_admin[0].name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.argocd_admin
  ]
}

###########################
# App Client for ArgoCD   #
###########################

resource "aws_cognito_user_pool_client" "argocd" {
  count = var.create_argocd_user_pool ? 1 : 0

  name         = "${var.user_pool_name}-argocd-client"
  user_pool_id = aws_cognito_user_pool.argocd[0].id

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
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Attributes
  read_attributes  = ["email", "email_verified", "name", "phone_number"]
  write_attributes = ["email", "name", "phone_number"]
}

