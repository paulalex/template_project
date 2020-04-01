#!/bin/bash
set -x
exec 1> /var/tmp/user_data.log 2>&1
echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts

# Set swappiness to zero
sysctl vm.swappiness=0
echo "vm.swappiness = 0" >> /etc/sysctl.conf

##############################################################
# Set timezone to London
##############################################################
timedatectl set-timezone "Europe/London"

# Get packages up to date
apt-get -y update

# Download the key for Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get -y update

# Install software we need (including things jenkins needs)
apt-get install -y unzip nginx git apt-transport-https ca-certificates curl \
        software-properties-common openjdk-8-jre-headless language-pack-en \
        clamav sysstat awscli

# Install python and required modules
apt-get install -y python-setuptools python-pip libssl-dev
pip install awscli boto3 virtualenv

# Install jenkins in a line one its own to ensure that the pre-requisite software has been installed.
apt-get install -y jenkins
systemctl stop jenkins

# Download and install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get install -y docker-ce

# Download and install Docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

#Add kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Install helm
wget https://get.helm.sh/helm-v3.1.1-linux-amd64.tar.gz
tar xzvf helm-v3.1.1-linux-amd64.tar.gz
cd linux-amd64/
cp helm /usr/local/bin/helm
rm helm-v3.1.1-linux-amd64.tar.gz
chmod 755 helm

# Install jq
sudo apt-get update
sudo apt-get install jq -y

# Install AWS IAM Authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator
cp aws-iam-authenticator /usr/local/bin

# Install terraform 0.12.20
curl -s -o terraform_0.12.20_linux_amd64.zip https://releases.hashicorp.com/terraform/0.12.20/terraform_0.12.20_linux_amd64.zip
unzip terraform_0.12.20_linux_amd64.zip
sudo mv terraform /usr/local/bin/
chmod 755 terraform
terraform --version

${mount_volume}