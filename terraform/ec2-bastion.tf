locals {
  user_data_bastion = <<-EOT
    #!/bin/bash

    echo "${tls_private_key.app_ssh_key.private_key_pem}" > /home/ec2-user/.ssh/id_rsa
    chmod 600 /home/ec2-user/.ssh/id_rsa
    chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

    yum update

    # Install pip
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&  python3 get-pip.py

    # Install ansible
    python3 -m pip install --user ansible
    python3 -m pip install --user argcomplete

    # Download app code
    cd /home/ec2-user
    curl -L -o app.zip https://github.com/danny-zh/terraform_aws_app_service/archive/refs/heads/main.zip
    unzip -o app.zip

    directory="terraform_aws_app_service-main"
    chown -hR ec2-user:ec2-user $directory
    chmod 2775 $directory
    find $directory -type d -exec chmod -R 2775 {} \;
    find $directory -type f -exec chmod -R 0664 {} \;

  EOT
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

  user_data = local.user_data_bastion

  tags = {
      Name = "Bastion-Server-${count.index}" 
  }
  depends_on = [aws_db_instance.app_database_rds, aws_instance.app_backend, aws_instance.app_frontend]
}