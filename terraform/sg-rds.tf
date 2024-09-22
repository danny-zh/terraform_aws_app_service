# Import security group module, define permitted inbound traffic for bastion tier
module "db_backend_security_group" {
  source      = "terraform-aws-modules/security-group/aws//modules/web"
  version     = "4.17.0"
  name        = "db-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for RDS under private backend subnet tier for database traffic"
  vpc_id      = module.vpc.vpc_id


  ingress_with_source_security_group_id = [{
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    source_security_group_id = module.app_backend_security_group.security_group_id
    description              = "Accept database traffic only from backend instances"
    }
  ]

  tags = var.aws_resource_tags
}