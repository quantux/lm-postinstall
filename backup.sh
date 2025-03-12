#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Vars
REGULAR_USER_NAME=$(who am i | awk '{print $1}')
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})
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

# Compactar e criptografar diretamente com tar e gpg
echo "Archiving and encrypting..."
echo "$password2" | tar --warning="no-file-ignored" --exclude-from=ignore-files -cz -C /home "$REGULAR_USER_NAME" | \
    gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 -o "$ENCRYPTED_FILE"

# Alterar o proprietário do arquivo criptografado
chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" "$ENCRYPTED_FILE"

# Backup to Cloud Storage usando interpolação diretamente
user_do "rclone move --progress $ENCRYPTED_FILE $GDRIVE_PATH"
echo "Backup concluído!"

# Excluindo arquivos antigos...
docker exec rclone rclone delete --min-age $((FILES_TO_KEEP * 7))d "$GDRIVE_PATH"
