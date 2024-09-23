#!/bin/bash
yum update
yum install -y git npm

# Install pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py &&  python3 get-pip.py

# Install ansible
python3 -m pip install --user ansible
python3 -m pip install --user argcomplete

# Download backend ans ansible code
cd /home/ec2-user
git init --initial-branch=main
git remote add -f origin https://github.com/danny-zh/terraform_aws_app_service.git
git sparse-checkout init --cone
git sparse-checkout set ansible movie_app/movie-analyst-api
git pull origin main

# Start service
cd /home/ec2-user/movie_app/movie-analyst-api
npm install && npm install pm2
npm test
pm2 start server.js