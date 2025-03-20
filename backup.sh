#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Vars
REGULAR_USER_NAME="${SUDO_USER:-$LOGNAME}"
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})
TODAY=$(date +"%d-%m-%Y")
ENCRYPTED_FILE="assets/backups/home-${TODAY}.tar.gz.gpg"
GDRIVE_PATH="gdrive:/Áreas/Família/Matheus/Backups/Backups\ Linux/"

user_do() {
    if command -v zsh >/dev/null 2>&1; then
        su - ${REGULAR_USER_NAME} -c "/bin/zsh --login -c '$1'"
    else
        su - ${REGULAR_USER_NAME} -c "/bin/bash -c '$1'"
    fi
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

# Archive and encrypt in one step
echo "Archiving and encrypting with tar and gpg..."
tar --warning="no-file-ignored" -cz -C /home/$REGULAR_USER_NAME --exclude-from=ignore-files . | \
    gpg --batch --yes --passphrase "$password" --pinentry-mode loopback -c --cipher-algo AES256 -o "$ENCRYPTED_FILE"

chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" "$ENCRYPTED_FILE"

# Backup to Cloud Storage
user_do "rclone move --progress $ENCRYPTED_FILE $GDRIVE_PATH"
echo "Backup concluído!"

# Excluindo arquivos antigos...
user_do "rclone delete --min-age $((FILES_TO_KEEP * 7))d \"$GDRIVE_PATH\""
