#!/bin/bash
#
jump_ip=${1}
private_key_path=${2}
#
#
#
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${jump_ip} || true
scp -o StrictHostKeyChecking=no -i ${2} bash/alb-ui-api.sh ubuntu@${jump_ip}:/home/ubuntu/alb-ui-api.sh
scp -o StrictHostKeyChecking=no -i ${2} gslb_db/geo.txt ubuntu@${jump_ip}:/home/ubuntu/geo.txt
scp -o StrictHostKeyChecking=no -i ${2} gslb_db/geo.txt.gz ubuntu@${jump_ip}:/home/ubuntu/geo.txt.gz