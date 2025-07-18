#!/bin/bash

# Clean LXC configuration for container 106
cat > /tmp/106_clean.conf << 'EOF'
arch: amd64
cores: 2
features: nesting=1
hostname: radarr
memory: 4096
mp0: /media,mp=/media
net0: name=eth0,bridge=vmbr0,firewall=1,gw=192.168.86.1,hwaddr=BC:24:11:56:86:30,ip=192.168.86.79/24,mtu=1500,type=veth
onboot: 1
ostype: ubuntu
rootfs: standard-lvm:vm-106-disk-0,size=8G
startup: order=20
swap: 4096
unprivileged: 1
lxc.mount.auto: cgroup:mixed proc:mixed sys:mixed
# LXC Mount Points - Managed by Ansible
mp0: /media,mp=/media

# User ID Mappings - Managed by Ansible
lxc.idmap: u 0 100000 1000
lxc.idmap: u 1000 1000 1000
lxc.idmap: u 2000 101000 64536
lxc.idmap: g 0 100000 1000
lxc.idmap: g 1000 1000 1000
lxc.idmap: g 2000 101000 64536
EOF

sudo cp /tmp/106_clean.conf /etc/pve/lxc/106.conf
