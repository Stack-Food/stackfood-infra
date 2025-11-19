###########################
# Application Client      #
###########################

resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.user_pool_name}-internal-apps"
  user_pool_id = aws_cognito_user_pool.main.id

  # Não gerar secret para aplicação móvel/web
  generate_secret = false

  # Token validity
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  # Fluxos de autenticação permitidos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH", # Para autenticação padrão
    "ALLOW_CUSTOM_AUTH",        # Para autenticação customizada com CPF
    "ALLOW_REFRESH_TOKEN_AUTH"  # Para renovar tokens
  ]

  # Prevenir vazamento de informações sobre existência de usuários
  prevent_user_existence_errors = "ENABLED"

  # Atributos que podem ser lidos
  read_attributes = ["custom:cpf", "custom:user_type", "preferred_username", "email", "name"]

  # Não usar OAuth flows para aplicação direta (usando SDK)
  # OAuth flows removidos para evitar necessidade de callback URLs
}

###########################
# ArgoCD Client           #
###########################

resource "aws_cognito_user_pool_client" "argocd" {
  name         = "${var.user_pool_name}-argocd-client"
  user_pool_id = aws_cognito_user_pool.main.id

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
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

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

  # Attributes - incluindo grupos nos claims
  read_attributes  = ["email", "email_verified", "name", "custom:user_type"]
  write_attributes = ["email", "name"]

  # Configurações para incluir grupos no token
  depends_on = [aws_cognito_user_pool.main]
}

###########################
# Grafana Client (Future) #
###########################

resource "aws_cognito_user_pool_client" "grafana" {
  name         = "${var.user_pool_name}-grafana-client"
  user_pool_id = aws_cognito_user_pool.main.id

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
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  # Callback URLs for Grafana
  callback_urls = var.grafana_callback_urls
  logout_urls   = var.grafana_logout_urls

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
  read_attributes  = ["email", "email_verified", "name", "custom:user_type"]
  write_attributes = ["email", "name"]

  depends_on = [aws_cognito_user_pool.main]
}

###########################
# SonarQube Client        #
###########################

resource "aws_cognito_user_pool_client" "sonarqube" {
  name         = "${var.user_pool_name}-sonarqube-client"
  user_pool_id = aws_cognito_user_pool.main.id

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
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  # Callback URLs for SonarQube
  callback_urls = var.sonarqube_callback_urls
  logout_urls   = var.sonarqube_logout_urls

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
  read_attributes  = ["email", "email_verified", "name", "custom:user_type"]
  write_attributes = ["email", "name"]

  depends_on = [aws_cognito_user_pool.main]
}
