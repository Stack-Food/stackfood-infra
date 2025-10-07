# Locals para organizar a lógica de integração com o NLB
locals {
  # Determinar qual NLB usar
  nlb_found = length(data.aws_lb.eks_nlb) > 0

  # Determinar qual protocolo usar com base nos listeners disponíveis
  has_https_listener = length(data.aws_lb_listener.selected443) > 0
  has_http_listener  = length(data.aws_lb_listener.selected80) > 0

  # Construir a URI de integração
  integration_protocol = local.has_https_listener ? "https" : "http"
  integration_port     = local.has_https_listener ? "443" : "80"

  # URI completa para a integração
  integration_uri = local.nlb_found ? "${local.integration_protocol}://${data.aws_lb.eks_nlb[0].dns_name}" : null

  # Tags comuns para recursos
  common_tags = merge(var.tags, {
    Environment = var.environment
    Cluster     = var.eks_cluster_name
    Component   = "api-gateway"
    Purpose     = "EKS-Integration"
  })
}
