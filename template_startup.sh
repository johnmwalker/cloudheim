#!/bin/bash

# This file doesn't actually get used directly, it's just here for easy reference
# The contents of this file is what the template is set to run automagically

# I think we start in root by default, but never trust defaults
cd /

# Install git and get the repo
sudo apt-get update
sudo apt-get install -y git

# Install gh
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
&& sudo mkdir -p -m 755 /etc/apt/keyrings \
&& wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

echo "mypat" | sudo tee mytoken.txt
sudo gh auth login --with-token < mytoken.txt

# Set up Git
git clone https://github.com/johnmwalker/cloudheim.git
sudo git config --global --add safe.directory /cloudheim

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
sudo ./startup.sh

