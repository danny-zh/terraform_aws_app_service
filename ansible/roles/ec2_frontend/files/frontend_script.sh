#!/bin/bash
set -ex

yum update
yum install -y npm

directory=${1:-"/home/ec2-user/frontend"}

# Install app dependencies
cd ${directory}
sudo npm install
npm test

# Change file permissions
cd ..
chown -hR ec2-user:ec2-user ${directory}
chmod 2775 ${directory}
find ${directory} -type d -exec chmod -R 2775 {} \;
find ${directory} -type f -exec chmod -R 0664 {} \;

# Start server
npm install pm2@latest -g
cd ${directory}
sudo -u ec2-user pm2 start server.js
