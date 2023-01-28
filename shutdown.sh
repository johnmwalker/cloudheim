#!/bin/bash

cd /cloudheim
git pull

sudo docker-compose down

sudo cp -r /valheim/saves/* /cloudheim/panerabread/
git add panerabread
git commit -m "AUTO: Shutdown save"
git push 
