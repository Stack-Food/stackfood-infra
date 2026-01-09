# Data source para obter informações do service após criação
data "kubernetes_service_v1" "nginx_ingress_public" {
  metadata {
    name      = "${helm_release.nginx_ingress_public.name}-controller"
    namespace = var.namespace
  }

  depends_on = [
    helm_release.nginx_ingress_public
  ]
}
