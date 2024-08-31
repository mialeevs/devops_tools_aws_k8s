#!/bin/bash

MY_IP=$(curl -s https://api.ipify.org)

cd tools

terraform destroy -var="my_ip=${MY_IP}" --auto-approve

cd ..

rm -f tempkey.pem
