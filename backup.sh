#!/bin/bash

if [ "$UID" -ne 0 ] || [ -z "$SUDO_USER" ]; then
  echo "Execute com sudo a partir de um usuário comum"; exit 1
fi

# Global
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="/home/$USER_NAME"
EXCLUDE_FILE="$USER_HOME/.scripts/lm-postinstall/ignore-files"

# Pergunta onde fazer o backup
echo "Onde deseja fazer o backup?"
echo "1) Local ($USER_HOME/restic/restic_repo)"
echo "2) Nuvem (Google Drive via rclone)"
read -rp "Escolha 1 ou 2: " choice

case "$choice" in
  1)
    LOCAL_PATH="$USER_HOME/restic/restic_repo"
    if [ ! -d "$LOCAL_PATH" ]; then
      echo "O caminho $LOCAL_PATH não existe. Saindo..."
      exit 1
    fi
    RESTIC_REPO="$LOCAL_PATH"
    ;;
  2)
    RESTIC_REPO="rclone:gdrive:/restic_repo"
    ;;
  *)
    echo "Opção inválida. Saindo..."
    exit 1
    ;;
esac

# Para os containers Docker usando docker compose
echo "Parando containers com docker compose..."
docker compose -f "$USER_HOME/.scripts/docker-apps/docker-compose.yml" down

# Backup do dconf
mkdir -p "$USER_HOME/.dconf"
dconf dump / > "$USER_HOME/.dconf/dconf"

# Check if file exists
if [ -f "$EXCLUDE_FILE" ]; then
  echo "Usando arquivo de exclusão: $EXCLUDE_FILE"
else
  echo "Arquivo de exclusão não encontrado, nenhum arquivo será ignorado."
fi

# Executa o backup com restic
echo "Iniciando backup com Restic no repositório: $RESTIC_REPO"
restic -r "$RESTIC_REPO" backup "$USER_HOME" --exclude-file="$EXCLUDE_FILE" -vv --tag mths --tag linux_mint

# Depois do backup, sobe os containers novamente
echo "Subindo containers com docker compose..."
docker compose -f "$USER_HOME/.scripts/docker-apps/docker-compose.yml" up -d

echo "Backup concluído com sucesso!"
