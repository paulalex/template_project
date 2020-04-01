#!/bin/bash
set -ex
exec 1> /var/tmp/user_data.log 2>&1

apt_wait () {
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 ; do
    sleep 1
  done
  if [ -f /var/log/unattended-upgrades/unattended-upgrades.log ]; then
    while sudo fuser /var/log/unattended-upgrades/unattended-upgrades.log >/dev/null 2>&1 ; do
      sleep 1
    done
  fi
}

# Set hostname into hosts file
echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts

########################################
# Set timezone to London               #
########################################
timedatectl set-timezone "Europe/London"

# Set swappiness to zero
sysctl vm.swappiness=0
echo "vm.swappiness = 0" >> /etc/sysctl.conf

# Disable unattended updates
apt_wait
apt update
apt install -y lvm2 jq awscli

# Attach elastic IP
instanceid=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

aws ec2 associate-address --instance-id $${instanceid} --allocation-id ${eip_identifier} --region $${region}

${mount_volume}

if [ ! -d "/data/openvpn_as" ]; then
    ${vpnas_path}/scripts/sacli --key "vpn.server.google_auth.enable" --value "true" ConfigPut
    ${vpnas_path}/scripts/sacli --key "host.name" --value "${public_fqdn_name}" ConfigPut
fi

service openvpnas stop

# Create sym link at start
if [ ! -d "/data/openvpn_as" ]; then
    mkdir -p /data/openvpn_as
    cp -R ${vpnas_path}/* /data/*
fi

# Remove default vpnas folders to allow symlink to EBS volume
rm -rf ${vpnas_path}

chown -R openvpnas: /data/openvpn_as

# Symlink OpenVPN-AS folders to the mounted data volume
ln -sfn /data/openvpn_as ${vpnas_path}

systemctl enable openvpnas.service
systemctl start openvpnas.service

echo "openvpn:${admin_password}" | sudo chpasswd