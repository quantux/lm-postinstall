#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Vars
REGULAR_USER_NAME="${SUDO_USER:-$LOGNAME}"
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})
TODAY=$(date +"%d-%m-%Y")
HOME="/home/$REGULAR_USER_NAME"
BACKUP_DIR="$HOME/.scripts/lm-postinstall/assets/backups"
TAR_FILE="$BACKUP_DIR/home-${TODAY}.tar.gz"
ENCRYPTED_FILE="${TAR_FILE}.gpg"
GDRIVE_PATH="gdrive:/Áreas/Família/Matheus/Backups/Backups Linux/"
FILES_TO_KEEP=8

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

# Criação do diretório de backup, se necessário
mkdir -p "$BACKUP_DIR"

# Arquivando com tar e mostrando progresso
echo "Criando o arquivo .tar.gz..."
tar --warning="no-file-ignored" -cvz -C /home/$REGULAR_USER_NAME --exclude-from=tar-ignore . -f "$TAR_FILE"

# Criptografando com gpg
echo "Criptografando o backup com GPG..."
gpg --batch --yes --passphrase "$password" --pinentry-mode loopback -c --cipher-algo AES256 -o "$ENCRYPTED_FILE" "$TAR_FILE"

# Ajusta a propriedade
chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" "$ENCRYPTED_FILE"

# Remove o tar desnecessário após criptografar
rm -f "$TAR_FILE"

# Backup para a nuvem
user_do "rclone move --progress \"$ENCRYPTED_FILE\" \"$GDRIVE_PATH\""
echo "Backup concluído!"

# Excluir backups antigos
user_do "rclone delete --min-age $((FILES_TO_KEEP * 7))d \"$GDRIVE_PATH\""
