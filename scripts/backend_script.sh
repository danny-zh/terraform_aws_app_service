#!/bin/bash
set -ex
yum update
yum install -y npm
yum npm install
source "db_variables.sh"
npm test