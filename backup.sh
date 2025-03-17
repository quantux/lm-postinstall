#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Vars
REGULAR_USER_NAME=$(who am i | awk '{print $1}')
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})
BACKUP_FILE="assets/backups/home.tar.gz"
TODAY=$(date +"%d-%m-%Y")
ENCRYPTED_FILE="assets/backups/home-${TODAY}.tar.gz.gpg"
GDRIVE_PATH="gdrive:/Áreas/Família/Matheus/Backups/Backups\ Linux/"

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

# Dconf backup
mkdir -p /home/$REGULAR_USER_NAME/.dconf
user_do "dconf dump / > /home/$REGULAR_USER_NAME/.dconf/dconf"
chown $REGULAR_USER_NAME:$REGULAR_USER_NAME /home/$REGULAR_USER_NAME/.dconf/dconf

# Backup using rsync
mkdir -p assets/backups/home
rsync -aAXv --progress --exclude-from=ignore-files /home/$REGULAR_USER_NAME/ assets/backups/home

echo "Archiving with tar..."
tar --warning="no-file-ignored" -czf $BACKUP_FILE -C assets/backups home/
rm -rf assets/backups/home

# Encrypt using gpg com interpolação de string
echo "Encrypting..."
echo "$password2" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 -o "$ENCRYPTED_FILE" "$BACKUP_FILE"
chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" "$ENCRYPTED_FILE"
rm -rf "$BACKUP_FILE"

# Backup to Cloud Storage usando interpolação diretamente
user_do "rclone move --progress $ENCRYPTED_FILE $GDRIVE_PATH"
echo "Backup concluído!"

# Excluindo arquivos antigos...
docker exec rclone rclone delete --min-age $((FILES_TO_KEEP * 7))d "$GDRIVE_PATH"
