#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Get current regular user (not sudo user)
RUID=$(who | awk 'FNR == 1 {print $1}')
RUSER_UID=$(id -u ${RUID})

user_do() {
    sudo -u ${RUID} /bin/bash -c "$1"
}

# start_uploading() {
#   echo "Uploading file..."
#   user_do "mkdir -p /home/$RUID/GDrive"
#   user_do "google-drive-ocamlfuse /home/$RUID/GDrive"
#   user_do "rsync -auv --progress --partial --delete assets/backups/home.tar.gz.gpg /home/$RUID/GDrive/Backups/"
#   umount /home/$RUID/GDrive
#   rm -rf /home/$RUID/GDrive
#   # rm -rf assets/backups/home.tar.gz.gpg
# }

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

echo "Archiving with tar..."
tar -czf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home

# Encrypt using gpg
echo "Encrypting..."
echo $password2 | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 assets/backups/home.tar.gz
chown $RUID:$RUID assets/backups/home.tar.gz.gpg
rm -rf assets/backups/home.tar.gz

# Start uploading?
# while true; do
#   read -p "Start uploading? (Y/n): " response
#   response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
#   if [ "$response" = "y" ] || [ "$response" = "yes" ]; then
#     start_uploading
#     break
#   elif [ "$response" = "n" ] || [ "$response" = "no" ]; then
#     echo "Backup completed."
#     break
#   fi
# done
