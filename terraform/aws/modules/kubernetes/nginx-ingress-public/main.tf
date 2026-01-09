resource "helm_release" "nginx_ingress_public" {
  name             = "nginx-ingress-public"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = var.namespace
  create_namespace = true
  version          = var.chart_version

  values = [
    file("${path.module}/nginx-public.yaml")
  ]

  timeout = 600

  depends_on = [
    var.depends_on_resources
  ]
}
