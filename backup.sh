#!/bin/bash

# Prevent script from running as root
if [[ $EUID -eq 0 ]]; then
  echo "This script must NOT be run as root" 1>&2
  exit 1
fi

username=$(whoami)
ignore_trash="/home/$username/.local/share/Trash"
tar --exclude="$ignore_trash" -cvzf ./assets/backups/home.tar.gz -C ~ -T ./assets/backups/files-to-backup
gpg -c --cipher-algo AES256 ./assets/backups/home.tar.gz
rm ./assets/backups/home.tar.gz
