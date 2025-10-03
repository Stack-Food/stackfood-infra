resource "aws_security_group" "vpc_link" {
  name   = var.security_group_name
  vpc_id = var.vpc_id

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic to NLB
  ingress {
    description = "HTTPS from API Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic to NLB
  ingress {
    description = "HTTP from API Gateway"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = var.security_group_name
      Environment = var.environment
      Purpose     = "API Gateway VPC Link to NGINX Ingress NLB"
    },
    var.tags
  )
}

resource "aws_apigatewayv2_vpc_link" "eks" {
  name               = var.vpc_link_name
  security_group_ids = [aws_security_group.vpc_link.id]
  # Use apenas subnets privadas para o VPC Link (mais seguro)
  subnet_ids = var.private_subnet_ids

  tags = merge(
    {
      Name        = var.vpc_link_name
      Environment = var.environment
      Cluster     = var.eks_cluster_name
      Purpose     = "Connect API Gateway to NGINX Ingress NLB"
    },
    var.tags
  )
}
