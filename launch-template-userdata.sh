#!/bin/bash
# ============================================================================
# CLOUDHEIM LAUNCH TEMPLATE USER-DATA (Valheim 1.0 revive, 2026-09)
# ============================================================================
# Paste this as the user-data of a NEW VERSION of launch template
# lt-00b98ae78e8a14de0 (EC2 console -> Launch Templates -> Versions ->
# Create new version, or `aws ec2 create-launch-template-version`).
#
# Replace these three placeholders before saving:
#   YOUR_GITHUB_PAT   - PAT with repo (write) scope for johnmwalker/cloudheim
#   YOUR_PASSWORD     - the Valheim server join password (min 5 chars)
#   YOUR_WEBHOOK_URL  - Discord webhook for server notifications (optional;
#                       delete the line to run without webhooks)
#
# After creating the version, note its number (e.g. 33) and run the
# "Launch Cloudheim" workflow with template_version set to that number.
# ============================================================================

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

echo "YOUR_GITHUB_PAT" | sudo tee mytoken.txt
sudo gh auth login --with-token < mytoken.txt
# Let git push authenticate through gh (used by autosave.sh / shutdown.sh)
sudo gh auth setup-git

# Set up Git
git clone https://github.com/johnmwalker/cloudheim.git
sudo git config --global --add safe.directory /cloudheim

# Server password and webhook get appended to env.list at boot
# (not committed to the repo)
cd cloudheim
echo "PASSWORD=YOUR_PASSWORD" >> env.list
echo "WEBHOOK_URL=YOUR_WEBHOOK_URL" >> env.list

# Run the startup script in the background
chmod +x startup.sh
sudo ./startup.sh

# less /var/log/cloud-init-output.log # then press capital F
