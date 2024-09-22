# Import security group module, define permitted inbound traffic for ALB
module "lb_security_group_external" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "4.17.0"

  name        = "Ext-lb-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ELB to accept traffic from the internet"
  vpc_id      = module.vpc.vpc_id



  ingress_cidr_blocks = ["0.0.0.0/0"] #Traffic from the internet

  ingress_rules = ["http-80-tcp"]

}