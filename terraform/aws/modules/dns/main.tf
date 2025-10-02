resource "cloudflare_record" "argocd" {
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
