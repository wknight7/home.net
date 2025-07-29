#!/bin/sh

# Alpine Linux Bootstrap Script
# Update package manager and install Ansible
apk update
apk add --no-cache ansible
apk add --no-cache openssh
apk add --no-cache git
apk add --no-cache curl
apk add --no-cache sudo
apk add --no-cache bash

# Backup original sshd_config if it exists
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
    chmod a-w /etc/ssh/sshd_config.original
fi

# Enable SSH service
rc-update add sshd default
service sshd start

# Download the Ansible playbook
curl -O http://192.168.86.83/bootstrap-alpine.yml

# Run the Ansible playbook using ansible-playbook command
ansible-playbook -i localhost, bootstrap-alpine.yml
