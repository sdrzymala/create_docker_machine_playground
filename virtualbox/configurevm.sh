#!/bin/bash
# Remember that line endings should be LF
echo "Start config script" && \
export DEBIAN_FRONTEND=noninteractive && \
currentusername=$1 && \
currentsambapass=$2 && \
echo "Configure sudo" && \
echo $currentusername ' ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo && \
adduser $currentusername sudo && \
echo "Update ubuntu" && \
export TERM=xter && \
echo "console-setup   console-setup/charmap47 select  UTF-8" > encoding.conf && \
debconf-set-selections encoding.conf && \
rm encoding.conf && \
apt-get update -y && \
#apt-get upgrade -y && \
#apt-get dist-upgrade -y && \
echo "Install basic stuff" && \
apt-get install -y vim && \
apt-get install -y curl && \
apt-get install -y id-utils && \
apt-get install -y net-tools && \
apt-get install -y python-pip && \
apt-get install -y openssh-server && \
echo "Install Samba" && \
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
echo "Install Docker" && \
curl -fsSL https://get.docker.com -o get-docker.sh && \
sh get-docker.sh &> /dev/null && \
curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &> /dev/null && \
chmod a+rx /usr/local/bin/docker-compose && \
usermod -aG docker $currentusername && \
echo "Finish config script" && \
exit 0