#!/bin/bash

cd /cloudheim
sudo git pull

sudo docker-compose down

sudo cp -r /valheim/saves/* /cloudheim/panerabreade/
sudo git add panerabreade
sudo git commit -m "AUTO: Shutdown save"
sudo git push 
