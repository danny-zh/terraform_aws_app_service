#!/bin/bash
set -ex

yum update
yum install -y npm

# Change file permissions
cd /home/ec2-user
chown -hR ec2-user:ec2-user ./movie-analyst-ui 
chmod 2775 ./movie-analyst-ui
find ./movie-analyst-ui -type d -exec chmod 2775 {} \;
find ./movie-analyst-ui -type f -exec chmod 0664 {} \;

# Install app dependencies
cd ./movie-analyst-ui
npm install
npm install pm2@latest -g

#npm test
#pm2 start server.js
