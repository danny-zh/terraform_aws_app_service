
# Import security group module, define permitted inbound traffic for app backend tier
module "app_backend_security_group" {
  source      = "terraform-aws-modules/security-group/aws//modules/web"
  version     = "4.17.0"
  name        = "backend-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ec2 under private backend subnet tier for HTTP traffic"
  vpc_id      = module.vpc.vpc_id


  ingress_with_source_security_group_id = [{
    from_port                = var.aws_backend_instance_port
    to_port                  = var.aws_backend_instance_port
    protocol                 = "tcp"
    source_security_group_id = module.alb_tcp_internal.security_group_id
    description              = "Accept http traffic only from interal elb"
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.app_bastion_security_group.security_group_id
      description              = "Accept ssh traffic only from bastion host"
    }
  ]

}