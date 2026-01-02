resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  timeout         = 600
  wait            = true
  wait_for_jobs   = true
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/prometheus.yml", {
      retention_days     = var.retention_days
      enable_persistence = var.enable_persistence
      storage_size       = var.storage_size
      storage_class      = var.storage_class
    })
  ]
}
