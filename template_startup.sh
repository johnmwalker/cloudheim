#!/bin/bash

# This file doesn't actually get used directly, it's just here for easy reference
# The contents of this file is what the template is set to run automagically

# I think we start in root by default, but never trust defaults
cd /

# Install git and get the repo
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/johnmwalker/cloudheim.git

# This isn't good practice long term, but for now, I'm gonna manually include the webhook url and server password in the template
cd cloudheim
echo "PASSWORD=mypass" >> env.list
echo "WEBHOOK_URL=myurl" >> env.list

# Run the startup script in the background
chmod +x startup.sh
./startup.sh &
