# Create app host ssh key pair. For SSH access to backend and frontend instances
resource "tls_private_key" "app_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "app_ssh_key" {
  key_name   = "app_ssh_key"
  public_key = tls_private_key.app_ssh_key.public_key_openssh
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