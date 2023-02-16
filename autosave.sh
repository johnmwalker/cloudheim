#!/bin/bash

cd /cloudheim

dir="/valheim/backups"

unset -v latest
for file in "$dir"/*.tar.gz; do
  [[ $file -nt $latest ]] && latest=$file
done

echo $latest

# Unpack the latest tar.gz to backups folder
if [ -f $latest ]; then
	tar -xzvf $latest -C /valheim/backups

	# Move the db and fwl files
	sudo mv `ls -t /valheim/backups/saves/worlds_local/*.db | head -1` /cloudheim/panerabread/worlds_local/panerabread.db
	sudo mv `ls -t /valheim/backups/saves/worlds_local/*.fwl | head -1` /cloudheim/panerabread/worlds_local/panerabread.fwl

	# Commit just the world files for the autosave
	sudo git add panerabread
	sudo git commit -m 'AUTO: Autosave'
	sudo git push

	# Cleanup before the next
	rm -rf /valheim/backups/saves
fi

