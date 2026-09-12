#!/bin/bash

HOME="${HOME:-/root}"

cd /cloudheim
sudo git pull

sudo docker compose down

world="rip_hermeto"
saves="/valheim/saves"

# Copy the current save state out for the shutdown commit. A world only
# counts once it has a completed save: 1.0 format writes _main.<gen>.ok,
# pre-1.0 wrote <world>.db.
world_saved=0
if compgen -G "$saves/worlds_local/$world/_main.*.ok" >/dev/null 2>&1; then
  world_saved=1
elif [ -f "$saves/worlds_local/$world.db" ]; then
  world_saved=1
fi

if [ "$world_saved" = "1" ]; then
  # Replace the world wholesale so stale chunk files from older save
  # generations do not accumulate in the repo.
  sudo rm -rf /cloudheim/$world/worlds_local
  sudo cp -r "$saves/worlds_local" /cloudheim/$world/worlds_local
else
  echo "No completed save for $world found in $saves; not copying world data."
fi

# Operator lists and prefs are small and worth mirroring too
sudo cp -f "$saves/adminlist.txt" "$saves/bannedlist.txt" \
  "$saves/permittedlist.txt" "$saves/prefs" /cloudheim/$world/ 2>/dev/null || true

sudo git add $world
if sudo git diff --cached --quiet; then
  echo "No world changes to commit."
else
  sudo git commit -m "AUTO: Shutdown save"
  sudo git push
fi
