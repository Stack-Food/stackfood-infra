# Locals simplificados para construir URIs
locals {
  # Lambda ARN (se disponível)
  lambda_arn = length(data.aws_lambda_function.this) > 0 ? data.aws_lambda_function.this[0].arn : null
  lambda_uri = local.lambda_arn != null ? "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${local.lambda_arn}/invocations" : null

  # EKS Load Balancer DNS (se disponível)
  eks_dns = length(data.aws_lb.eks_nlb) > 0 ? data.aws_lb.eks_nlb[0].dns_name : null

  # URI final para cada integração
  integration_uris = {
    for k, v in var.integrations : k => (
      v.integration_type == "lambda" && local.lambda_uri != null ? local.lambda_uri :
      v.integration_type == "eks" && local.eks_dns != null ? "http://${local.eks_dns}${v.eks_path}" :
      v.uri != null ? v.uri :
      ""
    )
  }
}
