#!/bin/bash

# Prevent script from running as root
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root" 1>&2
  exit 1
fi

username=$(whoami)
mkdir -p assets/backups
rsync -aAXv --progress --exclude-from=ignore-files /home/$username/ assets/backups/home
tar -cvzf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home
gpg --pinentry-mode loopback -c --cipher-algo AES256 assets/backups/home.tar.gz
rm -rf assets/backups/home.tar.gz
