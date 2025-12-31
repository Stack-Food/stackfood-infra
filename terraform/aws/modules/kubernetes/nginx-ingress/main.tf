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
}

# Wait for NGINX Ingress admission webhook to be ready
resource "null_resource" "wait_for_ingress_webhook" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for NGINX Ingress admission webhook to be ready..."
      for i in {1..60}; do
        if kubectl get endpoints ingress-nginx-controller-admission -n ${var.ingress_namespace} 2>/dev/null | grep -q ingress-nginx-controller-admission; then
          echo "NGINX Ingress admission webhook is ready!"
          exit 0
        fi
        echo "Attempt $i/60: Webhook not ready yet, waiting 5 seconds..."
        sleep 5
      done
      echo "WARNING: Webhook may not be ready after 5 minutes, but continuing anyway..."
      exit 0
    EOT
  }

  depends_on = [helm_release.ingress-nginx]
}

# Data source to get the LoadBalancer service information
data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = var.ingress_namespace
  }

  depends_on = [null_resource.wait_for_ingress_webhook]
}
