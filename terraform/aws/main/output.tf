output "argocd_access_info" {
  description = "Informações de acesso ao ArgoCD"
  value = {
    url                    = module.argocd.argocd_url
    admin_user             = "stackfood"
    admin_password         = "Fiap@2025"
    cognito_login_url      = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${module.cognito.user_pool_id}"
    admin_password_command = module.argocd.admin_password_command
  }
  sensitive = true
}

output "dns_records_created" {
  description = "Registros DNS criados"
  value = {
    argocd_dns = module.dns.argocd_dns_name
    argocd_url = module.dns.argocd_url
  }
}

output "cognito_configuration" {
  description = "Configuração do Cognito"
  value = {
    user_pool_id          = module.cognito.user_pool_id
    stackfood_user_status = module.cognito.stackfood_user_created
  }
}
