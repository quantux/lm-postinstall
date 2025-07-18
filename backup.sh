#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

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
    RESTIC_REPO="/media/hdd/restic_repo"
    ;;
  *)
    echo "Opção inválida. Saindo..."
    exit 1
    ;;
esac

# Pausa os containers Docker
echo "Pausando containers Docker..."
PAUSED_CONTAINERS=$(docker ps -q)
if [ -n "$PAUSED_CONTAINERS" ]; then
  docker pause $PAUSED_CONTAINERS
else
  echo "Nenhum container em execução para pausar."
fi

# Backup do dconf
mkdir -p "$HOME/.dconf"
dconf dump / > "$HOME/.dconf/dconf"

# Executa o backup com restic
echo "Iniciando backup com Restic no repositório: $RESTIC_REPO"
restic -r "$RESTIC_REPO" backup "$HOME" --exclude-file "$EXCLUDE_FILE" -vv --tag mths --tag linux_mint

echo "Backup concluído com sucesso!"
