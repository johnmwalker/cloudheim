#!/bin/bash

cd /cloudheim
sudo git pull

sudo docker-compose down

sudo cp -r /valheim/saves/* /cloudheim/panerabread/
sudo git add panerabread
sudo git commit -m "AUTO: Shutdown save"
sudo git push 
