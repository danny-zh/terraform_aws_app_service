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

  user_data = file("../scripts/init-script.sh")

  tags = {
      Name = "Frontend-Server-${count.index}"
    }
}