resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

# two target groups - same app box, different port per env
resource "aws_lb_target_group" "prod" {
  name        = "${var.project_name}-prod-tg"
  port        = var.prod_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-prod-tg" }
}

resource "aws_lb_target_group" "staging" {
  name        = "${var.project_name}-staging-tg"
  port        = var.staging_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-staging-tg" }
}

resource "aws_lb_target_group_attachment" "prod" {
  target_group_arn = aws_lb_target_group.prod.arn
  target_id        = var.app_instance_id
  port             = var.prod_port
}

resource "aws_lb_target_group_attachment" "staging" {
  target_group_arn = aws_lb_target_group.staging.arn
  target_id        = var.app_instance_id
  port             = var.staging_port
}

# default goes to prod, staging host header routes to the staging TG
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod.arn
  }
}

resource "aws_lb_listener_rule" "staging" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging.arn
  }

  condition {
    host_header {
      values = [var.staging_host_header]
    }
  }
}
