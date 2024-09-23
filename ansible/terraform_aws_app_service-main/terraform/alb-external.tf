# Resource to genere a 3 letter random string
resource "random_string" "lb_id" {
  length  = 3
  special = false
}

# Import alb module, create an ALB
module "alb_http_external" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "9.11.0"
  internal        = false # Must associate a public ip address to be reachable from the internet
  name            = "Ext-lb-${random_string.lb_id.result}-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  vpc_id          = module.vpc.vpc_id
  security_groups = [module.lb_security_group_external.security_group_id]
  subnets         = module.vpc.public_subnets

  enable_deletion_protection = false

  listeners = {
    ex-http8080-redirect = {
      port     = 8080
      protocol = "HTTP"
      redirect = {
        port        = "80"
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }
    }
    ex-http-forward = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "frontend_instances"
      }
    }
  }

  target_groups = {
    frontend_instances = {
      name_prefix       = "h1"
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false #Instances will be added later

      #target_id = aws_instance.app_frontend[0].id #Why cannot add a list of instances?
      #target_id = each.value.id #Why cannot add a list of instances?
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/data.php"
        port                = "80"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  }

  tags = var.aws_resource_tags
}

# Attach instances to alb target group
resource "aws_lb_target_group_attachment" "tg_attachment_external" {
  # count = length(aws_instance.app_frontend.instance_ids)

  depends_on = [aws_instance.app_frontend]

  for_each = {
    for k, v in aws_instance.app_frontend :
    k => v
  }

  target_group_arn = module.alb_http_external.target_groups.frontend_instances.arn
  # target_id        = aws_instance.app_frontend.instance_ids[count.index]  # Attach each instance
  target_id = each.value.id
  port      = 80

}