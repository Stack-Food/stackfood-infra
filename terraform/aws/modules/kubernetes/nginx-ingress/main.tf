resource "helm_release" "ingress-nginx" {
  name             = var.ingress_name
  repository       = var.ingress_repository
  chart            = var.ingress_chart
  namespace        = var.ingress_namespace
  create_namespace = true
  version          = var.ingress_version
  values           = [file("${path.module}/nginx.yaml")]

  set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = var.ssl_certificate_arn
    }
  ]
}
