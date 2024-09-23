#!/bin/bash
yum update
yum install -y git npm

# Install pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&  python3 get-pip.py

# Install ansible
python3 -m pip install --user ansible
python3 -m pip install --user argcomplete

# Download app code
cd /home/ec2-user
curl -L -o app.zip https://github.com/danny-zh/terraform_aws_app_service/archive/refs/heads/main.zip
unzip -o app.zip

# Provision app instances
cd ./terraform_aws_app_service-main/ansible
ansible-playbook playbook.yml