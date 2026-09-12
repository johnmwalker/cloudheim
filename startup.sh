#!/bin/bash

# This is where we should be by default, but never trust defaults
cd /cloudheim

chmod +x shutdown.sh
chmod +x autosave.sh

# Setup the env
sudo apt-get update
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm -f get-docker.sh

# The container runs as steam (uid 111, group 1000). See docker-compose.yml
# for why not 1000:1000 yet (upstream #1507). All three volumes need:
#  - write for uid 111 (saves + server install)
#  - group-write for gid 1000 (backups are read/written across uid 111 and 1000)
sudo mkdir -p /valheim/saves /valheim/server /valheim/backups
sudo chmod -R 775 /valheim/saves /valheim/server /valheim/backups

# Seed the save volume with the committed world files, if any, THEN hand
# ownership to the container user so the server can overwrite them
if [ -d /cloudheim/rip_hermeto/worlds_local ]; then
  sudo cp -rf /cloudheim/rip_hermeto/. /valheim/saves/
fi
sudo chown -R 111:1000 /valheim/saves /valheim/server

# Begin the server uppening
docker compose up -d

# Launch autosave script
sudo watch -n 900 ./autosave.sh

# less /var/log/cloud-init-output.log # then press capital F
