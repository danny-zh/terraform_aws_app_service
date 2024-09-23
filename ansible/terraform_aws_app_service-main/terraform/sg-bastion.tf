
# Import security group module, define permitted inbound traffic for bastion tier
module "app_bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "4.17.0"

  name        = "bastion-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for baston tier"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"] #Traffic from internet

  ingress_rules = ["ssh-tcp"]

}

