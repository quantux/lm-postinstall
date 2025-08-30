#!/bin/bash

# Se não for root, relança o script com sudo
if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# Agora garantido como root
if [ -z "$SUDO_USER" ]; then
  echo "Execute com sudo a partir de um usuário comum"
  exit 1
fi

# Global
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
EXCLUDE_FILE="$USER_HOME/.scripts/lm-postinstall/ignore-files"
RESTIC_REPO="/media/restic/restic_notebook_repo"

# Testa se o repositório existe
if [ ! -d "$RESTIC_REPO" ]; then
  echo "O caminho $RESTIC_REPO não existe."
  exit 1
fi

# Testa se o restic está instalado
if command -v restic >/dev/null 2>&1; then
    echo "✅ Restic está instalado."
    restic version
else
    echo "❌ Restic não está instalado."
    exit 1
fi

# Backup do dconf
mkdir -p "$USER_HOME/.dconf"
dconf dump / > "$USER_HOME/.dconf/dconf"

# Para os containers Docker usando docker compose
echo "Parando containers com docker compose..."
docker compose -f "$USER_HOME/.scripts/docker-apps/docker-compose.yml" down

# Executa o backup com restic
echo "Iniciando backup com Restic no repositório: $RESTIC_REPO"
restic -r "$RESTIC_REPO" backup "$USER_HOME" --exclude-file="$EXCLUDE_FILE" -vv --tag mths --tag linux_mint

# Depois do backup, sobe os containers novamente
echo "Subindo containers com docker compose..."
docker compose -f "$USER_HOME/.scripts/docker-apps/docker-compose.yml" up -d

echo "Backup concluído com sucesso!"
