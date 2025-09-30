#####################
# RDS Module - Main #
#####################

# Create DB subnet group
resource "aws_db_subnet_group" "this" {
  name        = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.identifier}-subnet-group"
  description = "Database subnet group for ${var.identifier}"
  subnet_ids  = concat(var.private_subnet_ids, var.public_subnet_ids)

  tags = merge(
    {
      Name        = var.db_subnet_group_name != null ? var.db_subnet_group_name : "${var.identifier}-subnet-group"
      Environment = var.environment
    },
    var.tags
  )
}

# Create DB parameter group
resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0

  name        = var.parameter_group_name != null ? var.parameter_group_name : "${var.identifier}-pg"
  description = "Database parameter group for ${var.identifier}"
  family      = var.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    {
      Name        = var.parameter_group_name != null ? var.parameter_group_name : "${var.identifier}-pg"
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
  }
}

# Create DB option group (applicable for certain engines like MySQL or Oracle)
resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0

  name                     = var.option_group_name != null ? var.option_group_name : "${var.identifier}-og"
  option_group_description = "Database option group for ${var.identifier}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(
    {
      Name        = var.option_group_name != null ? var.option_group_name : "${var.identifier}-og"
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create KMS key for RDS encryption if requested
resource "aws_kms_key" "rds" {
  count = var.kms_key_id == null && var.storage_encrypted ? 1 : 0

  description         = "KMS key for RDS instance ${var.identifier} encryption"
  enable_key_rotation = true

  tags = merge(
    {
      Name        = "${var.identifier}-kms-key"
      Environment = var.environment
    },
    var.tags
  )
}

# Create security group for RDS
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for RDS instance ${var.identifier} - allows access from EKS"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name        = "${var.identifier}-sg"
      Environment = var.environment
      Purpose     = "RDS-Database-Access"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "egress_all" {
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "This value is required to allow outbound traffic from the RDS instance"
}

resource "aws_security_group_rule" "ingress_all" {
  from_port         = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "ingress"
  description       = "This value is required to allow inbound traffic to the RDS instance"
}

# Allow inbound traffic to the database port from EKS nodes
resource "aws_security_group_rule" "ingress_from_eks" {
  count = length(var.allowed_security_groups) > 0 ? length(var.allowed_security_groups) : 0

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = element(var.allowed_security_groups, count.index)
  description              = "Allow database access from EKS nodes"
}

# Allow inbound traffic from CIDR blocks if specified
resource "aws_security_group_rule" "cidr_ingress" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.allowed_cidr_blocks
}

# Create the RDS instance
resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  storage_type                = var.storage_type
  storage_encrypted           = var.storage_encrypted
  kms_key_id                  = var.storage_encrypted ? (var.kms_key_id != null ? var.kms_key_id : aws_kms_key.rds[0].arn) : null
  username                    = var.db_username
  password                    = var.manage_master_user_password ? null : var.db_password
  manage_master_user_password = var.manage_master_user_password ? true : null
  db_name                     = var.db_name
  port                        = var.port
  publicly_accessible         = var.publicly_accessible

  vpc_security_group_ids = [aws_security_group.this.id]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name      = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  multi_az          = var.multi_az
  availability_zone = var.multi_az ? null : var.availability_zone

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  deletion_protection       = var.deletion_protection

  apply_immediately            = var.apply_immediately
  performance_insights_enabled = var.performance_insights_enabled

  # Enhanced monitoring is NOT supported in AWS Academy
  monitoring_interval = 0
  # monitoring_role_arn = data.aws_iam_role.rds_role.arn  # Commented out for AWS Academy

  copy_tags_to_snapshot = true

  tags = merge(
    {
      Name        = var.identifier
      Environment = var.environment
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password,
      manage_master_user_password
    ]
  }
}
