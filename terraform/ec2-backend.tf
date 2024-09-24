
locals {
  user_data_backend = <<EOT
    #!/bin/bash

    yum update
    yum install -y mariadb105
    
    cat <<EOL >> /etc/profile
    export DB_HOST=${split(":", aws_db_instance.app_database_rds.endpoint)[0]}:${var.aws_backend_instance_port}
    export DB_USER=${var.db_admin_username}
    export DB_PASS=${var.db_admin_passwd}
    export DB_NAME=${var.db_database_name}
    export PORT=${var.aws_backend_instance_port}
    EOL
    source /etc/profile
  EOT
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

  user_data = local.user_data_backend
  
  tags =  {
      Name = "Backend-Server-${count.index}"
    }
}