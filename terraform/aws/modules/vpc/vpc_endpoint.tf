
# #####################
# # VPC Endpoints     #
# #####################

# # Security Group for VPC Endpoints
# resource "aws_security_group" "vpc_endpoints" {
#   name_prefix = "${var.vpc_name}-vpc-endpoints-sg-"
#   description = "Security group for VPC endpoints"
#   vpc_id      = aws_vpc.vpc.id

#   ingress {
#     description = "HTTPS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [aws_vpc.vpc.cidr_block]
#   }

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-vpc-endpoints-sg"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# # VPC Endpoint for ECR API
# resource "aws_vpc_endpoint" "ecr_api" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-ecr-api-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for ECR DKR
# resource "aws_vpc_endpoint" "ecr_dkr" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-ecr-dkr-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for EKS
# resource "aws_vpc_endpoint" "eks" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.eks"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "eks:DescribeCluster",
#           "eks:ListClusters"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-eks-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for EC2
# resource "aws_vpc_endpoint" "ec2" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeNetworkInterfaces",
#           "ec2:DescribeSecurityGroups",
#           "ec2:DescribeSubnets",
#           "ec2:DescribeVolumes",
#           "ec2:DescribeVolumesModifications",
#           "ec2:DescribeSnapshots",
#           "ec2:CreateTags",
#           "ec2:DescribeInstanceAttribute",
#           "ec2:DescribeInstanceTypes",
#           "ec2:DescribeImages"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-ec2-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for S3 (Gateway endpoint)
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [for rt in aws_route_table.route-table-private : rt.id]

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-s3-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for CloudWatch Logs
# resource "aws_vpc_endpoint" "logs" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "logs:DescribeLogGroups",
#           "logs:DescribeLogStreams"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-logs-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }

# # VPC Endpoint for STS (Security Token Service)
# resource "aws_vpc_endpoint" "sts" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [for subnet in aws_subnet.subnet-private : subnet.id]
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect    = "Allow"
#         Principal = "*"
#         Action = [
#           "sts:AssumeRole",
#           "sts:GetCallerIdentity"
#         ]
#         Resource = "*"
#       }
#     ]
#   })

#   tags = merge(
#     {
#       Name              = "${var.vpc_name}-sts-endpoint"
#       Terraform_Managed = "true"
#       Environment       = var.environment
#     },
#     var.tags
#   )
# }
