#!/bin/bash
# Remember that line endings should be LF
echo "Start config script" && \
export DEBIAN_FRONTEND=noninteractive && \
currentusername=$1
echo "Configure sudo" && \
echo $currentusername ' ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo && \
adduser $currentusername sudo && \
echo "Update ubuntu" && \
export TERM=xter && \
echo "console-setup   console-setup/charmap47 select  UTF-8" > encoding.conf && \
debconf-set-selections encoding.conf && \
rm encoding.conf && \
apt-get update -y && \
#apt-get update -y --fix-missing && \
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
apt-get install -y samba && \
apt-get install -y samba-common && \
apt-get install -y python-glade2 && \
apt-get install -y system-config-samba && \
mv /etc/samba/smb.conf /etc/samba/smb.conf.bak && \
echo "
#============================ Global definition ================================

[global]
workgroup = WORKGROUP
server string = Samba Server %v
netbios name = ubuntu1604
security = user
map to guest = bad user
name resolve order = bcast host
dns proxy = no
bind interfaces only = yes

#============================ Share Definitions ============================== 

[Public]
  path = /samba/public
  writable = yes
  guest ok = yes
  guest only = yes
  read only = no
  create mode = 0777
  directory mode = 0777
  force user = nobody
" >> /etc/samba/smb.conf && \
mkdir -p /samba/public && \
groupadd editorial && \
chgrp editorial /samba/public && \
chmod -R 770 /samba/public && \
usermod -aG editorial $currentusername
smbpasswd -a $currentusername
smbpasswd -e $currentusername
touch /samba/public/test.txt && \
systemctl restart nmbd && \
echo "Install Docker" && \
curl -fsSL https://get.docker.com -o get-docker.sh && \
sudo sh get-docker.sh && \
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
sudo chmod +x /usr/local/bin/docker-compose && \
usermod -aG docker $currentusername && \
echo "Finish config script" && \
exit 0