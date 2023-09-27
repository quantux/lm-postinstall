#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Get current regular user (not sudo user)
RUID=$(who | awk 'FNR == 1 {print $1}')
RUSER_UID=$(id -u ${RUID})

user_do() {
    sudo -u ${RUID} /bin/bash -c "$1"
}

# asks for password confirmation
while true; do
  read -s -p "GPG Password: " password
  echo
  read -s -p "Password confirmation: " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done

# Backup using rsync
mkdir -p assets/backups/home
rsync -aAXv --progress --exclude-from=ignore-files /home/$RUID/ assets/backups/home
tar -cvzf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home

# Encrypt using gpg
echo $password2 | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 assets/backups/home.tar.gz
chown $RUID:$RUID assets/backups/home.tar.gz.gpg
rm -rf assets/backups/home.tar.gz

# Upload to google drive
user_do "rclone sync -P ./assets/backups/home.tar.gz.gpg /home/$RUID/GDrive/Backups"

rm -rf assets/backups/home.tar.gz.gpg
