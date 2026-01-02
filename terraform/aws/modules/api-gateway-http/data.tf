data "aws_lbs" "internal" {
  tags = {
    "kubernetes.io/service-name" = "ingress-nginx/ingress-nginx-controller"
  }
}

data "aws_lb" "ingress_nlb" {
  arn = tolist(data.aws_lbs.internal.arns)[0]
}


data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.ingress_nlb.arn
  port              = 80
}
