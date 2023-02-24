#!/bin/bash

# Prevent script from running as root
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root" 1>&2
  exit 1
fi

username=$(whoami)
rsync -avr --info=PROGRESS --files-from=assets/backups/files-to-backup --exclude=".local/share/Trash" /home/$username/ assets/backups/home
tar -cvzf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home
gpg -c --cipher-algo AES256 assets/backups/home.tar.gz
rm -rf assets/backups/home.tar.gz
