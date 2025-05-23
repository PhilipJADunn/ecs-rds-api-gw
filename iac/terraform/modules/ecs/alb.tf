resource "aws_lb" "ecs-alb" {
  name               = "ecs-flask-alb"
  subnets            = var.ecs_public_subnet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  tags = var.tags
}

resource "aws_lb_listener" "https_forward" {
  load_balancer_arn = aws_lb.ecs-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs-tg.arn
  }
}

resource "aws_lb_target_group" "ecs-tg" {
  name        = "ecs-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "90"
    protocol            = "HTTP"
    matcher             = "200-299"
    timeout             = "20"
    path                = "/"
    unhealthy_threshold = "2"
  }
}