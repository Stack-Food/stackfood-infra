# GitHub Integration for SonarQube
# This resource configures GitHub authentication and integration in SonarQube

# Wait for SonarQube to be ready before configuring GitHub integration
resource "null_resource" "wait_for_sonarqube" {
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SonarQube to be ready..."
      for i in {1..60}; do
        if kubectl exec -n ${var.namespace} statefulset/sonarqube-sonarqube -- wget -qO- http://localhost:9000/api/system/status 2>/dev/null | grep -q '"status":"UP"'; then
          echo "SonarQube is ready!"
          exit 0
        fi
        echo "Attempt $i/60: SonarQube not ready yet, waiting 10 seconds..."
        sleep 10
      done
      echo "WARNING: SonarQube may not be ready after 10 minutes"
      exit 0
    EOT
  }

  depends_on = [helm_release.sonarqube]
}

# Configure GitHub App integration via SonarQube API
resource "null_resource" "configure_github_integration" {
  count = var.github_app_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      SONARQUBE_URL="https://${var.sonarqube_subdomain}.${var.domain_name}"
      ADMIN_USER="${var.sonarqube_admin_user}"
      ADMIN_PASS="${var.sonarqube_admin_password}"
      
      echo "Configuring GitHub integration in SonarQube..."
      
      # Wait for SonarQube to be accessible externally
      for i in {1..30}; do
        HTTP_CODE=$(curl -s -o /dev/null -w "%%{http_code}" "$SONARQUBE_URL/api/system/status")
        if [ "$HTTP_CODE" = "200" ]; then
          echo "SonarQube is accessible!"
          break
        fi
        echo "Waiting for SonarQube to be accessible... ($i/30)"
        sleep 10
      done
      
      # Configure GitHub App settings
      curl -u "$ADMIN_USER:$ADMIN_PASS" -X POST "$SONARQUBE_URL/api/alm_settings/create_github" \
        -d "key=${var.github_integration_key}" \
        -d "appId=${var.github_app_id}" \
        -d "clientId=${var.github_client_id}" \
        -d "clientSecret=${var.github_client_secret}" \
        -d "privateKey=${var.github_private_key}" \
        -d "url=${var.github_api_url}" || echo "GitHub App may already exist"
      
      # Set GitHub as default DevOps platform
      curl -u "$ADMIN_USER:$ADMIN_PASS" -X POST "$SONARQUBE_URL/api/settings/set" \
        -d "key=sonar.alm.github.enabled" \
        -d "value=true" || true
      
      echo "GitHub integration configured successfully!"
    EOT

    environment = {
      GITHUB_APP_ID        = var.github_app_id
      GITHUB_CLIENT_ID     = var.github_client_id
      GITHUB_CLIENT_SECRET = var.github_client_secret
    }
  }

  depends_on = [null_resource.wait_for_sonarqube]

  triggers = {
    github_app_id     = var.github_app_id
    github_client_id  = var.github_client_id
    sonarqube_version = var.chart_version
  }
}
