resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    templatefile("${path.module}/argocd.yaml", {
      domain_name           = var.domain_name
      argocd_subdomain      = var.argocd_subdomain
      cognito_user_pool_id  = var.cognito_user_pool_id
      cognito_client_id     = var.cognito_client_id
      cognito_client_secret = var.cognito_client_secret
      cognito_region        = var.cognito_region
      certificate_arn       = var.certificate_arn
      admin_group_name      = var.admin_group_name
      readonly_group_name   = var.readonly_group_name
    })
  ]
}
