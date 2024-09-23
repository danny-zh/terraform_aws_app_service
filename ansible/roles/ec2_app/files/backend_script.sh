#!/bin/bash
set -ex

yum update
yum install -y npm

# Change file permissions
cd /home/ec2-user
chown -R ec2-user:ec2-user ./movie-analyst-api 
chmod 2775 ./movie-analyst-api
find ./movie-analyst-api -type d -exec chmod 2775 {} \;
find ./movie-analyst-api -type f -exec chmod 0664 {} \;

# Install app dependencies
npm install
npm install pm2@latest -g
cd ./movie-analyst-api

#npm test
pm2 start server.js
