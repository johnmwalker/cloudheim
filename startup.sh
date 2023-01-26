#!/bin/bash

# This is where we should be by default, but never trust defaults
cd /cloudheim

# Make some dirs
mkdir -p /valheim/saves
mkdir -p /valheim/backups
# mkdir -p /home/ubuntu/.config
# mkdir -p /root/.config/rclone/

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
cp /cloudheim/panerabread/valheim_plus.cfg /valheim/

# Move wold files to docker volume location
cp -r /cloudheim/panerabread/* /valheim/saves/

# Begin the server uppening
sudo docker-compose up

watch -n 900 "sudo mv `ls -t /valheim/backups/*.db | head -1` /cloudheim/panerabread/panerabread.db; sudo mv `ls -t /valheim/backups/*.fwl | head -1` /cloudheim/panerabread/panerabread.fwl; git add panerabread ; git commit -m 'AUTO: Autosave' ; git push;"

# less /var/log/cloud-init-output.log # then press capital F