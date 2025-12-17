resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    templatefile("${path.module}/argocd.yaml", {
      domain_name               = var.domain_name
      argocd_subdomain          = var.argocd_subdomain
      cognito_user_pool_id      = var.cognito_user_pool_id
      cognito_client_id         = var.cognito_client_id
      cognito_client_secret     = var.cognito_client_secret
      cognito_region            = var.cognito_region
      cognito_client_issuer_url = var.cognito_client_issuer_url
      certificate_arn           = var.certificate_arn
      admin_group_name          = var.admin_group_name
      readonly_group_name       = var.readonly_group_name
      user_pool_name            = var.user_pool_name
    })
  ]
}

# Busca todos os arquivos YAML na pasta applications/
locals {
  application_files = fileset("${path.module}/applications", "*.yaml")

  # Filtra o template para não criar Application dele
  applications = {
    for file in local.application_files :
    trimsuffix(file, ".yaml") => file
    if file != "application-template.yaml"
  }
}

# Cria uma Application do ArgoCD para cada arquivo YAML na pasta applications/
resource "kubernetes_manifest" "argocd_applications" {
  for_each = local.applications

  manifest = yamldecode(file("${path.module}/applications/${each.value}"))

  depends_on = [
    helm_release.argocd
  ]
}
