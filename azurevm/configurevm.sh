#!/bin/bash
### update
sudo apt-get update
sudo apt-get install id-utils
### install docker and docker-compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
### grant access to docker
sudo chmod +x /usr/local/bin/docker-compose
for u in $(lid -g -n aa); do usermod -a -G docker $u; done
exec bash