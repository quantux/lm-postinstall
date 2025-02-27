#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Get regular user and id
REGULAR_USER_NAME=$(who am i | awk '{print $1}')
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})

user_do() {
    sudo -u ${REGULAR_USER_NAME} /bin/bash -c "$1"
}

# Define o caminho do Google Drive
GDRIVE_PATH="gdrive:/Áreas/Família/Matheus/Backups/Backups\ Linux/"

# Verifica se o diretório assets/backups está vazio (ignorando arquivos ocultos)
if [ "$(ls -A assets/backups | grep -v '^\.' )" ]; then
  clear
  echo "Aviso: assets/backups/ não está vazio."
  echo -n "Deseja excluir todos os arquivos e continuar? (Y/n) "
  read -r escolha
  if [[ "$escolha" =~ ^[Yy]?$ ]]; then
    rm -rf assets/backups/*
    echo "Arquivos excluídos. Continuando o backup..."
  else
    echo "Backup cancelado."
    exit 1
  fi
fi

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
tar --warning="no-file-ignored" -czf assets/backups/home.tar.gz -C assets/backups home/
rm -rf assets/backups/home

# Definir a data no formato DD-MM-YYYY
TODAY=$(date +"%d-%m-%Y")

# Caminho do arquivo original e nome do arquivo criptografado
BACKUP_FILE="assets/backups/home.tar.gz"
ENCRYPTED_FILE="assets/backups/home-${TODAY}.tar.gz.gpg"

# Encrypt using gpg com interpolação de string
echo "Encrypting..."
echo "$password2" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback -c --cipher-algo AES256 -o "$ENCRYPTED_FILE" "$BACKUP_FILE"
chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" "$ENCRYPTED_FILE"
rm -rf "$BACKUP_FILE"

# Backup to Cloud Storage usando interpolação diretamente
user_do "rclone move --progress $ENCRYPTED_FILE $GDRIVE_PATH"
echo "Backup concluído!"

# Excluindo arquivos antigos...
# Contar arquivos no diretório de backups do Google Drive
FILE_COUNT=$(user_do "rclone ls $GDRIVE_PATH | wc -l")

# Se o número de arquivos for maior que 10, exclua o arquivo mais antigo
if [ "$FILE_COUNT" -gt 10 ]; then
  echo "Número de arquivos no Google Drive: $FILE_COUNT. Apagando o arquivo mais antigo..."

  # Listar os arquivos e ordenar com base na data no nome do arquivo (extraindo a data do formato DD-MM-YYYY)
  OLDEST_FILE=$(user_do "rclone lsf --files-only $GDRIVE_PATH" | sort -t'-' -k2,2 -k3,3 -k4,4 | head -n 1)

  # Excluir o arquivo mais antigo
  user_do "rclone delete $GDRIVE_PATH$OLDEST_FILE"
  echo "Arquivo mais antigo ($OLDEST_FILE) excluído."
else
  echo "O número de arquivos no Google Drive está abaixo de 10. Nenhum arquivo será excluído."
fi
