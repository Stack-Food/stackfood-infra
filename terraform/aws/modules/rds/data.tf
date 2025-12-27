# Get available AZs
data "aws_availability_zones" "available" {}

# Data source for LabRole (if enhanced monitoring is needed in the future)
data "aws_iam_role" "rds_role" {
  name = var.rds_role_name
}

# Data source to get the latest available engine version for the specified major version
data "aws_rds_engine_version" "this" {
  engine       = var.engine
  version      = var.major_engine_version
  include_all  = false
  default_only = false
  latest       = true

  filter {
    name   = "engine-mode"
    values = ["provisioned"]
  }
}

# Data source to get the parameter group family for the engine version
data "aws_rds_engine_version" "family" {
  engine  = var.engine
  version = var.engine_version != null ? var.engine_version : data.aws_rds_engine_version.this.version
}
