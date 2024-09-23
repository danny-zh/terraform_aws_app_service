#!/bin/bash
echo "Hello from ${HOSTNAME}"

yum update
yum install -y npm

# Start service
cd /home/ec2-user/movie-analyst-api
#npm install && npm install pm2
#npm test
#pm2 start server.js
