#!/bin/bash

# This is where we should be by default, but never trust defaults
cd /cloudheim

# Make some dirs
mkdir -p /home/ubuntu/.config
mkdir -p /root/.config/rclone/

# Setup the env
sudo apt-get update
# sudo apt-get -y upgrade
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get update
sudo apt-get install -y docker-compose

# No more rsync for now, but we might come back to this
# cp /tmp/rclone.conf /root/.config/rclone/rclone.conf
# cp /tmp/rclone.conf /home/ubuntu/.rclone.conf

# Move config file to docker volume location
cp /cloudheim/valheim_plus.cfg /valheim/

# Move wold files to docker volume location
cp -r /cloudheim/panerabread/* /valheim/saves/

# Begin the server uppening
sudo docker-compose --detach up

