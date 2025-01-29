#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Get regular user and id
REGULAR_USER_NAME=$(who am i | awk '{print $1}')
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})

user_do() {
    sudo -u ${REGULAR_USER_NAME} /bin/bash -c "$1"
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

# Check if the assets/backups directory is empty
if [ "$(ls -A assets/backups)" ]; then
  echo "Warning: assets/backups/ is not empty. Exiting..."
  exit 1
fi

# Dconf backup & encrypt
mkdir -p /home/$REGULAR_USER_NAME/.dconf
user_do "dconf dump / > /home/$REGULAR_USER_NAME/.dconf/dconf"
chown $REGULAR_USER_NAME:$REGULAR_USER_NAME /home/$REGULAR_USER_NAME/.dconf/dconf

# Backup using rsync
mkdir -p assets/backups/home
rsync -aAXv --progress --exclude-from=ignore-files /home/$REGULAR_USER_NAME/ assets/backups/home

echo "Archiving with tar..."
tar --warning="no-file-ignored" -czf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home

# Encrypt using gpg
echo "Encrypting..."
echo $password2 | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 assets/backups/home.tar.gz
chown $REGULAR_USER_NAME:$REGULAR_USER_NAME assets/backups/home.tar.gz.gpg
rm -rf assets/backups/home.tar.gz
