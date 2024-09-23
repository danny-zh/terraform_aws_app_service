#!/bin/bash
set -ex

yum update
yum install -y npm

# Install app dependencies
cd /home/ec2-user/movie-analyst-ui
sudo npm install
npm test

# Change file permissions
cd ..
chown -hR ec2-user:ec2-user ./movie-analyst-ui 
chmod 2775 ./movie-analyst-ui
find ./movie-analyst-ui -type d -exec chmod -R 2775 {} \;
find ./movie-analyst-ui -type f -exec chmod -R 0664 {} \;

# Start server
npm install pm2@latest -g
cd /home/ec2-user/movie-analyst-ui
sudo -u ec2-user pm2 start server.js
