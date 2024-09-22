# Import security group module, define permitted inbound traffic for ALB
module "lb_security_group_internal" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "4.17.0"

  name        = "Int-lb-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ELB to accept traffic from the internet"
  vpc_id      = module.vpc.vpc_id



  ingress_with_source_security_group_id = [{
    from_port                = 3000
    to_port                  = 3000
    protocol                 = "tcp"
    source_security_group_id = module.app_frontend_security_group.security_group_id
    description              = "Accept http traffic only from frontend tier"
    }]

}