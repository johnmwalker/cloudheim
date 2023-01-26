#!/bin/bash

cd /cloudheim

# Unpack the latest tar.gz to backups folder
tar -xzf `ls -t /valheim/backups/*.tar.gz | head -1` -C /valheim/backups

# Move the db and fwl files
mv `ls -t /valheim/backups/saves/worlds_local/*.db | head -1` /cloudheim/panerabread/worlds_local/panerabread.db
mv `ls -t /valheim/backups/saves/worlds_local/*.fwl | head -1` /cloudheim/panerabread/worlds_local/panerabread.fwl

# Commit just the world files for the autosave
git add panerabread
git commit -m 'AUTO: Autosave'
git push

# Cleanup before the next
rm -rf /valheim/backups/saves

