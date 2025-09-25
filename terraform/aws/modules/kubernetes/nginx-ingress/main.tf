resource "helm_release" "ingress-nginx" {
  name             = var.ingress_name
  repository       = var.ingress_repository
  chart            = var.ingress_chart
  namespace        = var.ingress_namespace
  create_namespace = true
  version          = var.ingress_version
  values           = [file("${path.module}/nginx.yaml")]

  # Aumentar o timeout SIGNIFICATIVAMENTE e desativar recursos que podem causar problemas
  timeout = 600   # 10 minutos de timeout
  atomic  = false # Desativar para evitar que falhas desfaçam tudo
  wait    = true  # Não esperar pela conclusão da instalação

  # Desativar recursos que podem causar timeouts adicionais
  replace       = true
  recreate_pods = false
  force_update  = false

  # Validação de configuração para evitar problemas
  verify = false

  # Limitar a quantidade de histórico para evitar sobrecarga
  max_history = 3

  set = [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
      value = var.ssl_certificate_arn
      type  = "string"
    }
  ]
}
