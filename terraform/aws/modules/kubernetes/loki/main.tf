resource "helm_release" "loki" {
  name             = "loki-stack"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  timeout         = 1200
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/loki.yml", {
      retention_period   = var.retention_period
      enable_persistence = var.enable_persistence
      storage_size       = var.storage_size
    })
  ]
}
