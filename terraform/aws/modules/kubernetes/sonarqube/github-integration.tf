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

# Change admin password after SonarQube is ready
resource "null_resource" "change_admin_password" {
  count = var.sonarqube_new_admin_password != "" && var.sonarqube_new_admin_password != null ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      set -e
      
      SONARQUBE_URL="https://${var.sonarqube_subdomain}.${var.domain_name}"
      OLD_PASSWORD="${var.sonarqube_admin_password}"
      NEW_PASSWORD="${var.sonarqube_new_admin_password}"
      ADMIN_USER="${var.sonarqube_admin_user}"
      
      echo "Changing admin password in SonarQube..."
      
      # Wait for SonarQube to be accessible externally
      for i in {1..30}; do
        HTTP_CODE=$$(curl -s -o /dev/null -w "%%{http_code}" "$SONARQUBE_URL/api/system/status")
        if [ "$HTTP_CODE" = "200" ]; then
          echo "SonarQube is accessible!"
          break
        fi
        echo "Waiting for SonarQube to be accessible... ($i/30)"
        sleep 10
      done
      
      # Change the admin password
      RESPONSE=$$(curl -s -w "\n%%{http_code}" -u "$ADMIN_USER:$OLD_PASSWORD" -X POST "$SONARQUBE_URL/api/users/change_password" \
        -d "login=$ADMIN_USER" \
        -d "password=$NEW_PASSWORD" \
        -d "previousPassword=$OLD_PASSWORD")
      
      HTTP_CODE=$$(echo "$RESPONSE" | tail -n1)
      BODY=$$(echo "$RESPONSE" | head -n-1)
      
      if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
        echo "Admin password changed successfully!"
      else
        echo "Failed to change admin password. HTTP code: $HTTP_CODE"
        echo "Response: $BODY"
        exit 1
      fi
    EOT
  }

  depends_on = [null_resource.wait_for_sonarqube]

  triggers = {
    password_change = coalesce(var.sonarqube_new_admin_password, "")
  }
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
      # Use new password if it was changed, otherwise use the default password
      ADMIN_PASS="${coalesce(var.sonarqube_new_admin_password, var.sonarqube_admin_password)}"
      
      echo "Configuring GitHub integration in SonarQube..."
      
      # Wait for SonarQube to be accessible externally
      for i in {1..30}; do
        HTTP_CODE=$$(curl -s -o /dev/null -w "%%{http_code}" "$SONARQUBE_URL/api/system/status")
        if [ "$HTTP_CODE" = "200" ]; then
          echo "SonarQube is accessible!"
          break
        fi
        echo "Waiting for SonarQube to be accessible... ($i/30)"
        sleep 10
      done
      
      # Configure GitHub App settings using the correct API endpoint
      echo "Creating GitHub App configuration..."
      
      # Build curl command with optional webhook secret
      CURL_CMD="curl -s -w \"\n%%{http_code}\" -u \"$ADMIN_USER:$ADMIN_PASS\" -X POST \"$SONARQUBE_URL/api/alm_settings/create_github\" \
        -d \"key=${var.github_integration_key}\" \
        -d \"appId=${var.github_app_id}\" \
        -d \"clientId=${var.github_client_id}\" \
        -d \"clientSecret=${var.github_client_secret}\" \
        -d \"privateKey=${var.github_private_key}\" \
        -d \"url=${var.github_api_url}\""
      
      # Add webhook secret only if it's provided
      if [ "${coalesce(var.github_webhook_secret, "")}" != "" ]; then
        CURL_CMD="$CURL_CMD -d \"webhookSecret=${coalesce(var.github_webhook_secret, "")}\""
        echo "Webhook secret will be configured"
      else
        echo "Webhook secret not provided - webhook signature verification will be disabled"
      fi
      
      RESPONSE=$$(eval $CURL_CMD)
      
      HTTP_CODE=$$(echo "$RESPONSE" | tail -n1)
      BODY=$$(echo "$RESPONSE" | head -n-1)
      
      if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "204" ]; then
        echo "GitHub integration configured successfully!"
        echo "Response: $BODY"
      else
        echo "Failed to configure GitHub integration. HTTP code: $HTTP_CODE"
        echo "Response: $BODY"
        # Don't fail if the configuration already exists
        if echo "$BODY" | grep -q "already exists"; then
          echo "GitHub App configuration already exists, continuing..."
        else
          exit 1
        fi
      fi
    EOT
  }

  depends_on = [
    null_resource.wait_for_sonarqube,
    null_resource.change_admin_password
  ]

  triggers = {
    github_app_id     = var.github_app_id
    github_client_id  = var.github_client_id
    sonarqube_version = var.chart_version
    admin_password    = coalesce(var.sonarqube_new_admin_password, "")
  }
}
