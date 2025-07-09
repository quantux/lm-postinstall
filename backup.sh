#!/bin/bash

# Variáveis
REGULAR_USER_NAME="${USER}"
REGULAR_UID=$(id -u)
HOME="/home/$REGULAR_USER_NAME"
EXCLUDE_FILE="$HOME/.scripts/lm-postinstall/ignore-files"
RESTIC_REPO="rclone:gdrive:/restic_repo"

# Backup do dconf
mkdir -p "$HOME/.dconf"
dconf dump / > "$HOME/.dconf/dconf"

# Executa o backup com restic diretamente para o Google Drive
echo "Iniciando backup com Restic para Google Drive..."
restic -r "$RESTIC_REPO" backup "$HOME" --exclude-file "$EXCLUDE_FILE" --verbose --tag mths --tag linux_mint

echo "Backup concluído com sucesso!"
