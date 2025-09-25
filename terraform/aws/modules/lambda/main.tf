##########################
# Lambda Function Module #
##########################

# Data source para obter a IAM role existente
data "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "/aws/lambda/${var.function_name}"
      Environment = var.environment
    },
    var.tags
  )
}

# Security group for Lambda if deployed in VPC
resource "aws_security_group" "lambda" {
  count       = length(var.subnet_ids) > 0 ? 1 : 0
  name        = "${var.function_name}-lambda-sg"
  description = "Security group for Lambda function ${var.function_name}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.function_name}-lambda-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Lambda Function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = data.aws_iam_role.lambda_role.arn
  package_type  = var.package_type

  # For ZIP packages
  runtime  = var.package_type == "Zip" ? var.runtime : null
  handler  = var.package_type == "Zip" ? var.handler : null
  filename = data.archive_file.lambda_placeholder.output_path

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = concat([aws_security_group.lambda[0].id], var.security_group_ids)
    }
  }

  tags = merge(
    {
      Name        = var.function_name
      Environment = var.environment
    },
    var.tags
  )
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified,
    ]
  }
  depends_on = [aws_cloudwatch_log_group.lambda]
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  count         = var.create_api_gateway_permission ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = var.api_gateway_source_arn
}

# Lambda Permission for other services
resource "aws_lambda_permission" "other" {
  count         = length(var.additional_lambda_permissions)
  statement_id  = var.additional_lambda_permissions[count.index].statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = var.additional_lambda_permissions[count.index].principal
  source_arn    = lookup(var.additional_lambda_permissions[count.index], "source_arn", null)
}

# Lambda Alias
resource "aws_lambda_alias" "this" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = var.alias_description
  function_name    = aws_lambda_function.this.function_name
  function_version = var.function_version != null ? var.function_version : aws_lambda_function.this.version

  # Routing config for canary deployments
  dynamic "routing_config" {
    for_each = var.routing_additional_version_weight != null ? [1] : []
    content {
      additional_version_weights = {
        (var.routing_additional_version) = var.routing_additional_version_weight
      }
    }
  }
}
