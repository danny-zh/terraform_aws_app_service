
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

  tags = {
      Name = "Bastion-Server-${count.index}" 
  }
  depends_on = [aws_db_instance.app_database_rds]
}