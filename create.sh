#!/bin/bash
#
MY_IP=$(curl -s https://api.ipify.org)

cd tools

terraform init

terraform fmt

terraform apply -var="my_ip=${MY_IP}" --auto-approve

chmod 400 tempkey.pem

mv tempkey.pem ../
