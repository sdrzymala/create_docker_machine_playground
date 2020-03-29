#!/bin/bash
### get parameters
export DEBIAN_FRONTEND=noninteractive && \
currentusername=$1 && \
currentsambapass=$2 && \
sudo su && \
### update
apt-get update && \
apt-get install id-utils && \
### install and configure docker and docker-compose
curl -fsSL https://get.docker.com -o get-docker.sh && \
sh get-docker.sh && \
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
chmod +x /usr/local/bin/docker-compose && \
usermod -aG docker $currentusername && \
### install and configure samba
apt-get install -y samba samba-common python-glade2 system-config-samba && \
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak && \
echo "
[global]
 workgroup = WORKGROUP
 server string = Samba Server %v
 netbios name = ubuntu
 security = user
 map to guest = bad user
 name resolve order = bcast host
 wins support = yes

[shareddata]
 path = /shareddata
 available = yes
 valid users = @sambausers
 read only = no
 browseable = yes
 public = yes
 writable = yes

" >> /etc/samba/smb.conf && \
mkdir -p /shareddata && \
groupadd sambausers && \
usermod -aG sambausers $currentusername && \
chgrp sambausers /shareddata && \
chmod 777 /shareddata && \
echo -e $currentsambapass"\n"$currentsambapass | smbpasswd -a $currentusername && \
service smbd restart && \
exec bash