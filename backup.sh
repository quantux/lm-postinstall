#!/bin/bash

# Variáveis
REGULAR_USER_NAME="${SUDO_USER:-$USER}"
REGULAR_UID=$(id -u "$REGULAR_USER_NAME")
HOME=$(getent passwd "$REGULAR_USER_NAME" | cut -d: -f6)
EXCLUDE_FILE="$HOME/.scripts/lm-postinstall/ignore-files"

# Pergunta onde fazer o backup
echo "Onde deseja fazer o backup?"
echo "1) Nuvem (Google Drive via rclone)"
echo "2) Local (/media/hdd/restic_repo)"
read -rp "Escolha 1 ou 2: " choice

case "$choice" in
  1)
    RESTIC_REPO="rclone:gdrive:/restic_repo"
    ;;
  2)
    LOCAL_PATH="/media/hdd/restic_repo"
    if [ ! -d "$LOCAL_PATH" ]; then
      echo "O caminho $LOCAL_PATH não existe. Saindo..."
      exit 1
    fi
    RESTIC_REPO="$LOCAL_PATH"
    ;;
  *)
    echo "Opção inválida. Saindo..."
    exit 1
    ;;
esac

# Para os containers Docker usando docker compose
echo "Parando containers com docker compose..."
docker compose -f "$HOME/.scripts/docker-apps/docker-compose.yml" down

echo "Corrigindo permissões da pasta home apenas para arquivos e pastas com dono root..."
sudo find "$HOME" -user root -exec chown "$REGULAR_USER_NAME:$REGULAR_USER_NAME" {} +

# Backup do dconf
mkdir -p "$HOME/.dconf"
dconf dump / > "$HOME/.dconf/dconf"

# Executa o backup com restic
echo "Iniciando backup com Restic no repositório: $RESTIC_REPO"
restic -r "$RESTIC_REPO" backup "$HOME" --exclude-file "$EXCLUDE_FILE" -vv --tag mths --tag linux_mint

# Depois do backup, sobe os containers novamente
echo "Subindo containers com docker compose..."
docker compose -f "$HOME/.scripts/docker-apps/docker-compose.yml" up -d

echo "Backup concluído com sucesso!"
