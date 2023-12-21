#!/bin/bash
#
jump_ip=${1}
private_key_path=${2}
#
#
#
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${jump_ip} || true
