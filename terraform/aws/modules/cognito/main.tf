###########################
# Unified Cognito User Pool #
###########################

resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  # Configuração de MFA
  mfa_configuration = "OFF"

  # Configurações de verificação e recuperação
  auto_verified_attributes = ["email"]
  alias_attributes         = ["email"]

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

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      email_message = "Olá {username}! Bem-vindo ao StackFood! 🚀\n\nSua conta foi criada com sucesso. Use as credenciais abaixo para acessar:\n\nUsername: {username}\nSenha temporária: {####}\n\nVocê será solicitado a alterar sua senha no primeiro login.\n\nEquipe StackFood"
      email_subject = "🚀 Acesso ao StackFood - Bem-vindo à equipe!"
      sms_message   = "StackFood - Username: {username}, Senha temporária: {####}"
    }
  }

  # Schema personalizado para diferentes tipos de usuários
  schema {
    attribute_data_type = "String"
    name                = "user_type"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Schema para CPF (aplicação principal)
  schema {
    attribute_data_type = "String"
    name                = "cpf"
    required            = false
    mutable             = false

    string_attribute_constraints {
      min_length = 11
      max_length = 11
    }
  }

  tags = {
    Name        = var.user_pool_name
    Environment = var.environment
    Service     = "Unified Authentication"
    Purpose     = "Application and Management Systems"
  }
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.user_pool_name
  user_pool_id = aws_cognito_user_pool.main.id
}

###########################
# Groups                  #
###########################

# Grupo para aplicação principal
resource "aws_cognito_user_group" "app_users" {
  name         = "app-users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Usuários da aplicação principal StackFood"
  precedence   = 10
}

# Grupo para administradores da aplicação
resource "aws_cognito_user_group" "app_admins" {
  name         = "app-admins"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administradores da aplicação StackFood"
  precedence   = 5
}

# Grupo para ArgoCD
resource "aws_cognito_user_group" "argocd" {
  name         = "argocd"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Usuários com acesso ao ArgoCD"
  precedence   = 3
}

# Grupo para Grafana
resource "aws_cognito_user_group" "grafana" {
  name         = "grafana"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Usuários com acesso ao Grafana"
  precedence   = 4
}

# Grupo para SonarQube
resource "aws_cognito_user_group" "sonarqube" {
  name         = "sonarqube"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Usuários com acesso ao SonarQube"
  precedence   = 5
}

# Grupo para administradores de sistema
resource "aws_cognito_user_group" "system_admins" {
  name         = "system-admins"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administradores de sistema com acesso completo"
  precedence   = 1
}

###########################
# Users                   #
###########################

# Usuário convidado para aplicação
resource "aws_cognito_user" "guest" {
  count = var.create_guest_user ? 1 : 0

  user_pool_id = aws_cognito_user_pool.main.id
  username     = "convidado"
  password     = var.guest_user_password

  message_action = "SUPPRESS"

  attributes = {
    name               = "Usuário Convidado"
    email              = "convidado@stackfood.com.br"
    email_verified     = true
    "custom:user_type" = "guest"
    preferred_username = "convidado"
  }
}

# Adicionar usuário convidado ao grupo app-users
resource "aws_cognito_user_in_group" "guest_app_users" {
  count = var.create_guest_user ? 1 : 0

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.guest[0].username
  group_name   = aws_cognito_user_group.app_users.name

  depends_on = [
    aws_cognito_user.guest,
    aws_cognito_user_group.app_users
  ]
}

# Usuário admin principal StackFood
resource "aws_cognito_user" "stackfood_admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = "stackfood"
  password     = var.stackfood_admin_password

  message_action = "SUPPRESS"

  attributes = {
    name               = "StackFood Administrator"
    email              = "admin@stackfood.com.br"
    email_verified     = true
    "custom:user_type" = "system_admin"
  }
}

# Adicionar admin aos grupos
resource "aws_cognito_user_in_group" "stackfood_admin_system" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.system_admins.name
}

resource "aws_cognito_user_in_group" "stackfood_admin_argocd" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.argocd.name
}

resource "aws_cognito_user_in_group" "stackfood_admin_grafana" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.grafana.name
}

resource "aws_cognito_user_in_group" "stackfood_admin_sonarqube" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.sonarqube.name
}

# Usuários da equipe
resource "aws_cognito_user" "team_users" {
  for_each = var.team_users

  user_pool_id = aws_cognito_user_pool.main.id
  username     = each.key
  password     = var.team_users_password

  message_action = "SUPPRESS"

  attributes = {
    name               = each.value.name
    email              = each.value.email
    email_verified     = true
    "custom:user_type" = lookup(each.value, "user_type", "team_member")
  }

  depends_on = [aws_cognito_user_pool.main]
}

# Adicionar usuários da equipe aos grupos apropriados
resource "aws_cognito_user_in_group" "team_users_argocd" {
  for_each = {
    for username, user in var.team_users : username => user
    if contains(lookup(user, "groups", []), "argocd")
  }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.argocd.name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.argocd
  ]
}

resource "aws_cognito_user_in_group" "team_users_grafana" {
  for_each = {
    for username, user in var.team_users : username => user
    if contains(lookup(user, "groups", []), "grafana")
  }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.grafana.name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.grafana
  ]
}

resource "aws_cognito_user_in_group" "team_users_app_admins" {
  for_each = {
    for username, user in var.team_users : username => user
    if contains(lookup(user, "groups", []), "app-admins")
  }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.app_admins.name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.app_admins
  ]
}

resource "aws_cognito_user_in_group" "team_users_system_admins" {
  for_each = {
    for username, user in var.team_users : username => user
    if contains(lookup(user, "groups", []), "system-admins")
  }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.system_admins.name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.system_admins
  ]
}

resource "aws_cognito_user_in_group" "team_users_sonarqube" {
  for_each = {
    for username, user in var.team_users : username => user
    if contains(lookup(user, "groups", []), "sonarqube")
  }

  user_pool_id = aws_cognito_user_pool.main.id
  username     = aws_cognito_user.team_users[each.key].username
  group_name   = aws_cognito_user_group.sonarqube.name

  depends_on = [
    aws_cognito_user.team_users,
    aws_cognito_user_group.sonarqube
  ]
}
