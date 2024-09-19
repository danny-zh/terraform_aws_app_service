# Get data about available AZ in the region
data "aws_availability_zones" "az" {
  state = "available"
}

#Import vpc module, create a custom VPC first
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.0"

  cidr = var.aws_vpc_cidr_block
  azs  = data.aws_availability_zones.az.names


  private_subnets = [for i in range(var.aws_private_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i)]
  public_subnets  = [for i in range(var.aws_public_subnet_count) : cidrsubnet(var.aws_vpc_cidr_block, 4, i + 10)]


  #private_subnets = slice(var.aws_private_subnet_cidr_blocks, 0, var.aws_private_subnet_count)
  #public_subnets  = slice(var.aws_public_subnet_cidr_blocks, 0, var.aws_public_subnet_count)

  enable_nat_gateway = var.aws_enable_nat_gateway # For private subnets to access internet
  enable_vpn_gateway = var.aws_enable_vpn_gateway

  tags = merge(
    {
      Name = "VPC-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
    },
  var.aws_resource_tags)
}

# Import security group module, define permitted inbound traffic for app frontend tier
module "app_frontend_security_group" {
  source      = "terraform-aws-modules/security-group/aws//modules/web"
  version     = "4.17.0"
  name        = "frontend-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ec2 under public frontend subnet tier for HTTP traffic"
  vpc_id      = module.vpc.vpc_id


  ingress_with_source_security_group_id = [{
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    source_security_group_id = module.lb_security_group.security_group_id
    description              = "Accept http traffic only from load balancer"
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.app_bastion_security_group.security_group_id
      description              = "Accept ssh traffic only from bastion host"
    }
  ]

  tags = var.aws_resource_tags
}

# Import security group module, define permitted inbound traffic for app backend tier
module "app_backend_security_group" {
  source      = "terraform-aws-modules/security-group/aws//modules/web"
  version     = "4.17.0"
  name        = "backend-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ec2 under private backend subnet tier for HTTP traffic"
  vpc_id      = module.vpc.vpc_id


  ingress_with_source_security_group_id = [{
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    source_security_group_id = module.app_frontend_security_group.security_group_id
    description              = "Accept http traffic only from frontend tier"
    },
    {
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      source_security_group_id = module.app_bastion_security_group.security_group_id
      description              = "Accept ssh traffic only from bastion host"
    }
  ]

  tags = var.aws_resource_tags
}

# Import security group module, define permitted inbound traffic for bastion tier
module "app_bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "4.17.0"

  name        = "bastion-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for baston tier"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"] #Traffic from internet

  ingress_rules = ["ssh-tcp"]


  tags = var.aws_resource_tags
}

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

# Import security group module, define permitted inbound traffic for ALB
module "lb_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "4.17.0"

  name        = "lb-sg-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  description = "Security group for ELB to accept traffic from the internet"
  vpc_id      = module.vpc.vpc_id



  ingress_cidr_blocks = ["0.0.0.0/0"] #Traffic from the internet

  ingress_rules = ["http-80-tcp"]

  tags = var.aws_resource_tags
}

# Resource to genere a 3 letter random string
resource "random_string" "lb_id" {
  length  = 3
  special = false
}

# Import alb module, create an ALB
module "alb_http" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "9.11.0"
  internal        = false # Must associate a public ip address to be reachable from the internet
  name            = "lb-${random_string.lb_id.result}-${var.aws_resource_tags["project"]}-${var.aws_resource_tags["environment"]}"
  vpc_id          = module.vpc.vpc_id
  security_groups = [module.lb_security_group.security_group_id]
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
resource "aws_lb_target_group_attachment" "tg_attachment" {
  # count = length(aws_instance.app_frontend.instance_ids)

  depends_on = [aws_instance.app_frontend]

  for_each = {
    for k, v in aws_instance.app_frontend :
    k => v
  }

  target_group_arn = module.alb_http.target_groups.frontend_instances.arn
  # target_id        = aws_instance.app_frontend.instance_ids[count.index]  # Attach each instance
  target_id = each.value.id
  port      = 80

}

# Create app host ssh key pair. For SSH access to backend and frontend instances
resource "tls_private_key" "app_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app_ssh_key" {
  key_name   = "app_ssh_key"
  public_key = tls_private_key.app_ssh_key.public_key_openssh
}

# Create app frontend instances
resource "aws_instance" "app_frontend" {

  ami                         = var.aws_frontend_instance_ami
  instance_type               = var.aws_frontend_instance_type
  count                       = var.aws_frontend_instance_count
  monitoring                  = true # Provide metrics to cloudwatch
  associate_public_ip_address = true # Need to communicate with ELB

  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.app_frontend_security_group.security_group_id]

  key_name = aws_key_pair.app_ssh_key.key_name # SSH key pair name (for internal connection only)

  metadata_options {
    http_tokens   = "optional" # This allows both IMDSv1 and IMDSv2
    http_endpoint = "enabled"  # Enable the instance metadata service
  }

  user_data = file("init-script.sh")

  tags = merge(
    {
      Name = "Frontend-Server-${count.index}"
    },
    var.aws_resource_tags
  )
}

# Create app backend instances
resource "aws_instance" "app_backend" {

  ami                         = var.aws_backend_instance_ami
  instance_type               = var.aws_backend_instance_type
  count                       = var.aws_backend_instance_count
  monitoring                  = true  # Provide metrics to cloudwatch
  associate_public_ip_address = false # Instances in private subnet

  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [module.app_backend_security_group.security_group_id]

  key_name = aws_key_pair.app_ssh_key.key_name # SSH key pair name (for internal connection only)

  metadata_options {
    http_tokens   = "optional" # This allows both IMDSv1 and IMDSv2
    http_endpoint = "enabled"  # Enable the instance metadata service
  }

  user_data = <<-EOF
  #!/bin/bash
  yum update
  yum install -y mariadb105
  echo "export MYSQL_SERVER=${split(":", aws_db_instance.app_database_rds.endpoint)[0]}" >> /home/ec2-user/.bashrc
  EOF

  tags = merge(
    {
      Name = "Backend-Server-${count.index}"
    },
    var.aws_resource_tags
  )
}


# Create bastion host ssh key pair
resource "tls_private_key" "bastion_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "bastion_ssh_key"
  public_key = tls_private_key.bastion_ssh_key.public_key_openssh
}

resource "local_file" "bastion_ssh_key" {
  filename        = "${path.root}/bastion_host_key.pem"
  content         = tls_private_key.bastion_ssh_key.private_key_pem
  file_permission = "0600" # Set permissions so it's secure
}


# Create bastion host instance
resource "aws_instance" "bastion_host" {

  ami                         = var.aws_bastion_instance_ami
  instance_type               = var.aws_bastion_instance_type
  count                       = 1
  associate_public_ip_address = true
  monitoring                  = true

  subnet_id              = module.vpc.public_subnets[1]
  vpc_security_group_ids = [module.app_bastion_security_group.security_group_id]

  key_name = aws_key_pair.bastion_ssh_key.key_name # SSH key pair name to connect to bastion host

  metadata_options {
    http_tokens   = "optional" # This allows both IMDSv1 and IMDSv2
    http_endpoint = "enabled"  # Enable the instance metadata service
  }

  #user_data = file("init-script.sh")

  user_data = <<-EOF
    #!/bin/bash
    echo "${tls_private_key.app_ssh_key.private_key_pem}" > /home/ec2-user/.ssh/id_rsa
    chmod 600 /home/ec2-user/.ssh/id_rsa
    chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
  EOF

  tags = merge(
    {
      Name = "Bastion-Server-${count.index}"
    },
    var.aws_resource_tags
  )
  depends_on = [aws_db_instance.app_database_rds]
}

#Create subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_main"
  subnet_ids = module.vpc.private_subnets

  tags = var.aws_resource_tags
}

#Create RDS instance
resource "aws_db_instance" "app_database_rds" {
  allocated_storage = var.db_storage
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_type
  #db_name   = "db${random_string.lb_id.result}${var.aws_resource_tags["project"]}${var.aws_resource_tags["environment"]}"
  db_name              = "db_mysql"
  username             = var.db_admin_username
  password             = var.db_admin_passwd
  parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  skip_final_snapshot  = true
  publicly_accessible  = false # Or set to false for private access

  vpc_security_group_ids = [module.db_backend_security_group.security_group_id]
}
