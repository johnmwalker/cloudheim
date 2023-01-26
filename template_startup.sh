#!/bin/bash

# This file doesn't actually get used directly, it's just here for easy reference
# The contents of this file is what the template is set to run automagically

# I think we start in root by default, but never trust defaults
cd /

# Install git and get the repo
sudo apt-get update
sudo apt-get install -y git

# git config?
# git config credential.helper store
# git config credential.helper 'cache --timeout sometimeout'
# git config --local user.name user
# git config --local user.email email
git clone https://user:pat@github.com/johnmwalker/cloudheim.git
git config --global --add safe.directory /cloudheim

# This isn't good practice long term, but for now, I'm gonna manually include the webhook url and server password in the template
cd cloudheim
echo "PASSWORD=redacted" >> env.list
echo "WEBHOOK_URL=redacted" >> env.list

echo "test" >> test.txt
git add test.txt
git commit -m "Test"
git push 

# Run the startup script in the background
chmod +x startup.sh
chmod +x shutdown.sh
./startup.sh &

