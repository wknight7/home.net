#!/bin/bash

# Update package manager and install Ansible
sudo apt update
sudo apt install -y ansible
sudo apt install -y openssh-server
sudo apt install -y git
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
sudo chmod a-w /etc/ssh/sshd_config.original

# Download the Ansible playbook
curl -O http://192.168.86.83/bootstrap.yml

# Run the Ansible playbook using ansible-playbook command
ansible-playbook -i localhost bootstrap.yml