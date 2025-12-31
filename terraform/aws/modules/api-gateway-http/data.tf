data "aws_lb_listener" "http" {
  load_balancer_arn = var.lb_arn
  port              = 80
}
