#!/bin/bash

# This is where we should be by default, but never trust defaults
cd /cloudheim

# Make some dirs
mkdir -p /valheim/saves
mkdir -p /valheim/backups
chmod +x shutdown.sh
chmod +x autosave.sh

# Setup the env
sudo apt-get update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Move world files to docker volume location
cp -r /cloudheim/panerabreade/* /valheim/saves/

# Begin the server uppening
docker compose up -d

# Launch autosave script
sudo watch -n 900 ./autosave.sh

# less /var/log/cloud-init-output.log # then press capital F
