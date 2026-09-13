#!/bin/bash

# This is where we should be by default, but never trust defaults
cd /cloudheim

# Fail fast if the password was never injected by the launch template
# (odin otherwise fails AFTER the multi-GB download with a cryptic error)
if ! grep -q '^PASSWORD=..*' env.list; then
  echo "ERROR: env.list has no PASSWORD line. The launch-template user-data" >&2
  echo "should have appended it. Aborting before the server install." >&2
  exit 1
fi

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

# Seed the ValheimPlus config into the game-install volume. Must run BEFORE
# the chown below and BEFORE docker compose up (VP reads it at server start;
# on first boot Odin/BepInEx would otherwise generate a default one instead).
# The server dir does not exist until Odin's first install, so only copy when
# it does (subsequent boots); fresh instances pick the file up on boot #2, or
# pre-create the dir so it lands on boot #1.
if [ -f /cloudheim/org.bepinex.plugins.valheim_plus.cfg ]; then
  sudo mkdir -p /valheim/server/BepInEx/config
  sudo cp /cloudheim/org.bepinex.plugins.valheim_plus.cfg \
          /valheim/server/BepInEx/config/org.bepinex.plugins.valheim_plus.cfg
fi
sudo chown -R 111:1000 /valheim/saves /valheim/server /valheim/backups

# Begin the server uppening
docker compose up -d

# Autosave every 15 min via systemd (watch/ncurses has no TERM under
# cloud-init and dies; a unit also survives reboots and logs to journald)
sudo tee /etc/systemd/system/cloudheim-autosave.service >/dev/null <<'UNIT'
[Unit]
Description=Cloudheim autosave (extract latest backup, commit world to git)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/cloudheim
ExecStart=/cloudheim/autosave.sh

[Install]
WantedBy=multi-user.target
UNIT

sudo tee /etc/systemd/system/cloudheim-autosave.timer >/dev/null <<'UNIT'
[Unit]
Description=Run cloudheim autosave every 15 minutes

[Timer]
OnBootSec=20min
OnUnitActiveSec=15min
Unit=cloudheim-autosave.service

[Install]
WantedBy=timers.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now cloudheim-autosave.timer

# less /var/log/cloud-init-output.log # then press capital F
