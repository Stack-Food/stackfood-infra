
###########################
# ArgoCD User & Groups    #
###########################

# ArgoCD Admin Group
resource "aws_cognito_user_group" "argocd_admin" {
  name         = "argocd-admin"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "ArgoCD Administrator Group"
  precedence   = 1
}

# ArgoCD Readonly Group
resource "aws_cognito_user_group" "argocd_readonly" {
  name         = "argocd-readonly"
  user_pool_id = aws_cognito_user_pool.this.id
  description  = "ArgoCD Read-only Group"
  precedence   = 2
}

# StackFood Admin User
resource "aws_cognito_user" "stackfood_admin" {
  user_pool_id = aws_cognito_user_pool.this.id
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
  user_pool_id = aws_cognito_user_pool.this.id
  username     = aws_cognito_user.stackfood_admin.username
  group_name   = aws_cognito_user_group.argocd_admin.name
}

###########################
# App Client for ArgoCD   #
###########################

resource "aws_cognito_user_pool_client" "argocd" {
  name         = "${var.user_pool_name}-argocd-client"
  user_pool_id = aws_cognito_user_pool.this.id

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

