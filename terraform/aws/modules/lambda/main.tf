##########################
# Lambda Function Module #
##########################

# Data source para obter a IAM role existente
data "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name
}

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name        = var.bucket_name
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 1. Cria um arquivo .zip em memória a partir do placeholder
data "archive_file" "placeholder" {
  type        = "zip"
  source_file = "${path.module}/empty-function.zip"
  output_path = "${path.module}/empty-function.zip"
}

# 2. Faz o upload do placeholder .zip para o S3
resource "aws_s3_object" "lambda_placeholder" {
  bucket = aws_s3_bucket.this.id
  key    = "${var.function_name}.zip"
  source = data.archive_file.placeholder.output_path
  etag   = data.archive_file.placeholder.output_md5
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
  runtime     = var.package_type == "Zip" ? var.runtime : null
  handler     = var.package_type == "Zip" ? var.handler : null
  s3_bucket   = var.package_type == "Zip" ? var.bucket_name : null
  s3_key      = var.package_type == "Zip" ? "${var.function_name}.zip" : null
  s3_object_version = var.package_type == "Zip" ? var.s3_object_version : null
  timeout = 30

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
      s3_key,
      s3_object_version,
      source_code_hash,
      last_modified,
    ]
  }
}