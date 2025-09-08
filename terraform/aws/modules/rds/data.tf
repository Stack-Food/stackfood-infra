# Get available AZs
data "aws_availability_zones" "available" {}

# Data source for LabRole (if enhanced monitoring is needed in the future)
data "aws_iam_role" "rds_role" {
  name = var.rds_role_name
}
