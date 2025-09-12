######################
# EKS Cluster Module #
######################

# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-cluster-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Allow node to communicate with each other
  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # Allow all outbound traffic for downloads and updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-node-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for ALB (Internal Load Balancer)
resource "aws_security_group" "alb_internal" {
  name        = "${var.cluster_name}-alb-internal-sg"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  # Allow HTTP from within VPC
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow HTTPS from within VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-alb-internal-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for NLB (Public Load Balancer)
resource "aws_security_group" "nlb_public" {
  count       = var.create_public_nlb ? 1 : 0
  name        = "${var.cluster_name}-nlb-public-sg"
  description = "Security group for public NLB"
  vpc_id      = var.vpc_id

  # Allow HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow traffic to ALB
  egress {
    description     = "Traffic to internal ALB"
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_internal.id]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-nlb-public-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group for Remote Management
resource "aws_security_group" "management" {
  count       = var.enable_remote_management ? 1 : 0
  name        = "${var.cluster_name}-management-sg"
  description = "Security group for remote cluster management"
  vpc_id      = var.vpc_id

  # Allow kubectl access from specific IPs
  ingress {
    description = "kubectl access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.management_cidr_blocks
  }

  # Allow SSH to worker nodes (if needed)
  ingress {
    description = "SSH to worker nodes"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.management_cidr_blocks
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-management-sg"
      Environment = var.environment
    },
    var.tags
  )
}

# Security Group Rules (created after security groups to avoid cycles)

# Allow HTTPS from worker nodes to cluster
resource "aws_security_group_rule" "cluster_ingress_https_from_nodes" {
  description              = "HTTPS from worker nodes"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster.id
}

# Allow worker nodes to communicate with cluster
resource "aws_security_group_rule" "node_ingress_cluster_communication" {
  description              = "Allow worker nodes to communicate with cluster"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.node.id
}

# Allow ALB to access StackFood API HTTP port on nodes
resource "aws_security_group_rule" "node_ingress_alb_api_http" {
  description              = "StackFood API HTTP port from ALB"
  type                     = "ingress"
  from_port                = 5039
  to_port                  = 5039
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
  security_group_id        = aws_security_group.node.id
}

# Allow ALB to access StackFood API HTTPS port on nodes
resource "aws_security_group_rule" "node_ingress_alb_api_https" {
  description              = "StackFood API HTTPS port from ALB"
  type                     = "ingress"
  from_port                = 7189
  to_port                  = 7189
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
  security_group_id        = aws_security_group.node.id
}

# Allow ALB to access NodePort range on nodes
resource "aws_security_group_rule" "node_ingress_alb_nodeports" {
  description              = "NodePort range from ALB"
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
  security_group_id        = aws_security_group.node.id
}

# Allow ALB to send traffic to worker nodes
resource "aws_security_group_rule" "alb_egress_to_nodes" {
  description              = "Traffic to worker nodes"
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.alb_internal.id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = concat([aws_security_group.cluster.id], var.additional_security_group_ids)
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.kms_key_arn != null ? var.kms_key_arn : aws_kms_key.eks[0].arn
    }
  }

  # Enable EKS Control Plane Logging
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(
    {
      Name        = var.cluster_name
      Environment = var.environment
    },
    var.tags
  )
}

# Internal ALB for API Gateway and internal services
resource "aws_lb" "internal" {
  count              = var.create_internal_alb ? 1 : 0
  name               = "${var.cluster_name}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_internal.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      Name        = "${var.cluster_name}-internal-alb"
      Environment = var.environment
      Purpose     = "Internal API Gateway"
    },
    var.tags
  )
}

# Public NLB for external access (optional)
resource "aws_lb" "public" {
  count              = var.create_public_nlb ? 1 : 0
  name               = "${var.cluster_name}-public-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.nlb_public[0].id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    {
      Name        = "${var.cluster_name}-public-nlb"
      Environment = var.environment
      Purpose     = "Public API Access"
    },
    var.tags
  )
}

# KMS Key for EKS Secret Encryption
resource "aws_kms_key" "eks" {
  count = var.kms_key_arn == null ? 1 : 0

  description         = "KMS key for EKS cluster ${var.cluster_name} secret encryption"
  enable_key_rotation = true

  tags = merge(
    {
      Name        = "${var.cluster_name}-kms-key"
      Environment = var.environment
    },
    var.tags
  )
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = data.aws_iam_role.eks_node_role.arn
  subnet_ids      = var.node_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  ami_type       = each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  # Use launch template for more customization if needed
  dynamic "launch_template" {
    for_each = lookup(each.value, "launch_template", null) != null ? [each.value.launch_template] : []

    content {
      id      = launch_template.value.id
      version = launch_template.value.version
    }
  }

  # Enable remote access if specified
  dynamic "remote_access" {
    for_each = lookup(each.value, "ssh_key", null) != null ? [1] : []

    content {
      ec2_ssh_key               = each.value.ssh_key
      source_security_group_ids = var.enable_remote_management ? [aws_security_group.management[0].id] : []
    }
  }

  dynamic "taint" {
    for_each = lookup(each.value, "taints", [])

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  labels = lookup(each.value, "labels", {})

  tags = merge(
    {
      Name        = "${var.cluster_name}-${each.key}"
      Environment = var.environment
    },
    var.tags
  )

  update_config {
    max_unavailable_percentage = 33
  }

  lifecycle {
    create_before_destroy = true
  }

  # depends_on = [aws_security_group.node]
}

data "aws_cloudwatch_log_group" "existing_eks_cluster" {
  count = 1
  name  = "/aws/eks/${var.cluster_name}/cluster"
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = try(data.aws_cloudwatch_log_group.existing_eks_cluster[0].arn, null) == null ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    {
      Name        = "/aws/eks/${var.cluster_name}/cluster"
      Environment = var.environment
    },
    var.tags
  )
}

