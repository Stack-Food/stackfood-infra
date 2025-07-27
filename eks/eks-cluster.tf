resource "aws_eks_cluster" "eks_leo_cluster" {
  name = "eks-${var.project_name}"

  access_config {
    authentication_mode = var.accessConfig
  }

  role_arn = var.labRole
  version  = "1.33"

  vpc_config {
    subnet_ids = aws_subnet.subnet_public[*].id
    security_group_ids = [aws_security_group.sg.id]
  }

  

  tags = var.tags
}