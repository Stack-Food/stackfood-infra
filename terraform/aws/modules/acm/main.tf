######################
# ACM Certificate Module #
######################

# ACM Certificate
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = var.validation_method
  key_algorithm             = var.key_algorithm

  tags = merge(
    {
      Name        = "${var.domain_name}-certificate"
      Environment = var.environment
      Domain      = var.domain_name
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}
# Cloudflare record para validação DNS
# Como o mesmo registro de validação é usado para todos os domínios, podemos simplificar
locals {
  # Converte o conjunto domain_validation_options para uma lista para podermos acessar o primeiro elemento
  validation_options = tolist(aws_acm_certificate.this.domain_validation_options)
}

resource "cloudflare_record" "validation" {
  # Usamos apenas o primeiro registro de validação, já que são todos iguais
  allow_overwrite = true
  zone_id         = var.cloudflare_zone_id
  name            = local.validation_options[0].resource_record_name
  type            = local.validation_options[0].resource_record_type
  content         = local.validation_options[0].resource_record_value
  proxied         = false
  ttl             = 60

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_acm_certificate.this]
}

# Certificate validation
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  # Usando o hostname do único registro que criamos
  validation_record_fqdns = [cloudflare_record.validation.hostname]

  depends_on = [cloudflare_record.validation]
}
