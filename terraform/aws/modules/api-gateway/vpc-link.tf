# resource "aws_security_group" "vpc_link" {
#   name   = var.security_group_name
#   vpc_id = var.vpc_id

#   egress {
#     description = "All outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow HTTPS traffic to NLB
#   ingress {
#     description = "HTTPS from API Gateway"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # Allow HTTP traffic to NLB
#   ingress {
#     description = "HTTP from API Gateway"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(
#     {
#       Name        = var.security_group_name
#       Environment = var.environment
#       Purpose     = "API Gateway VPC Link to NGINX Ingress NLB"
#     },
#     var.tags
#   )
# }

# resource "aws_api_gateway_vpc_link" "eks" {
#   name               = var.vpc_link_name
#   security_group_ids = [aws_security_group.vpc_link.id]
#   # Use apenas subnets privadas para o VPC Link (mais seguro)
#   subnet_ids = var.private_subnet_ids

#   tags = merge(
#     {
#       Name        = var.vpc_link_name
#       Environment = var.environment
#       Cluster     = var.eks_cluster_name
#       Purpose     = "Connect API Gateway to NGINX Ingress NLB"
#     },
#     var.tags
#   )
# }


# resource "null_resource" "wait_for_nlb" {
#   triggers = {
#     nlb_arn = data.aws_lb.eks_nlb[0].arn
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       for i in {1..20}; do
#         state=$(aws elbv2 describe-load-balancers --load-balancer-arns ${data.aws_lb.eks_nlb[0].arn} --region ${data.aws_region.current.region} --query 'LoadBalancers[0].State.Code' --output text)
#         if [ "$state" = "active" ]; then
#           exit 0
#         fi
#         sleep 15
#       done
#       exit 1
#     EOT
#   }
# }

# # VPC Link para conectar API Gateway com EKS (se especificado)
# resource "aws_api_gateway_vpc_link" "eks" {

#   name        = "${var.api_name}-eks-vpc-link"
#   description = "VPC Link for ${var.api_name} to connect to EKS cluster ${var.eks_cluster_name}"
#   target_arns = length(data.aws_lb.eks_nlb) > 0 ? [data.aws_lb.eks_nlb[0].arn] : []

#   tags = merge(
#     {
#       Name        = "${var.api_name}-eks-vpc-link"
#       Environment = var.environment
#       Cluster     = var.eks_cluster_name
#     },
#     var.tags
#   )
#   depends_on = [null_resource.wait_for_nlb]
# }
