
# Import alb module, create an internal ALB
module "alb_tcp_internal" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "9.11.0"
  internal        = true # Internal ALB
  name            = "Int-lb-${random_string.lb_id.result}-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  vpc_id          = module.vpc.vpc_id
  security_groups = [module.lb_security_group_internal.security_group_id]
  subnets         = module.vpc.private_subnets

  enable_deletion_protection = false

  listeners = {
    ex-forward = {
      port     = 3000
      protocol = "TCP"
      forward = {
        target_group_key = "backend_instances"
      }
    }
  }

  target_groups = {
    backend_instances = {
      name_prefix       = "b1"
      protocol          = "TCP"
      port              = 3000
      target_type       = "instance"
      create_attachment = false #Instances will be added later

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "3000"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  }

}

# Attach instances to alb target group
resource "aws_lb_target_group_attachment" "tg_attachment_internal" {
  # count = length(aws_instance.app_frontend.instance_ids)

  depends_on = [aws_instance.app_backend]

  for_each = {
    for k, v in aws_instance.app_backend :
    k => v
  }

  target_group_arn = module.alb_tcp_internal.target_groups.backend_instances.arn
  target_id = each.value.id
  port      = 3000

}