#!/bin/bash

cd /cloudheim

sudo docker-compose down

sudo cp -r /valheim/saves/* ./
git add .
git commit -m "AUTO: Shutdown save"
git push 
