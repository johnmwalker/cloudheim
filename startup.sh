#!/bin/bash

mkdir -p /home/ubuntu/.config
mkdir -p /root/.config/rclone/

sudo apt-get update
# sudo apt-get -y upgrade

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get update
sudo apt-get install -y rclone docker-compose
cp /tmp/rclone.conf /root/.config/rclone/rclone.conf
cp /tmp/rclone.conf /home/ubuntu/.rclone.conf
rclone copy remote:panerabread /valheim/saves
cp /valheim/saves/valheim_plus.cfg /valheim/
sudo docker-compose up

