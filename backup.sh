#!/bin/bash

# Verifica se o sudo está instalado
if ! command -v sudo >/dev/null 2>&1; then
    echo "❌ O sudo não está instalado. Este script precisa do sudo."
    exit 1
fi

# Verifica se o script está sendo executado via sudo
if [ -z "$SUDO_USER" ]; then
    echo "❌ Execute este script usando sudo: sudo $0"
    exit 1
fi

# Global
USER_NAME="$SUDO_USER"
USER_UID=$(id -u "$USER_NAME")
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
EXCLUDE_FILE="$USER_HOME/.custom/lm-postinstall/ignore-files"
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

user_do() {
    sudo -u "$USER_NAME" bash -l -c "$1"
}

# Backup do dconf
user_do "mkdir -p $USER_HOME/.dconf"
user_do "dconf dump / > $USER_HOME/.dconf/dconf"

# Registra qual wallpaper está em uso. A imagem em si já é salva pelo restic;
# aqui guardamos apenas a escolha para reaplicá-la na restauração (etapa 26).
echo "Registrando wallpaper em uso..."
WALLPAPER_STATE="$USER_HOME/.config/lm-postinstall/wallpaper"
user_do "mkdir -p $USER_HOME/.config/lm-postinstall"
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${USER_UID}/bus' gsettings get org.cinnamon.desktop.background picture-uri > '$WALLPAPER_STATE'"

# Para os containers Docker usando docker compose
echo "Parando containers com docker compose..."
docker compose -f "$USER_HOME/.custom/docker-apps/docker-compose.yml" down

# Executa o backup com restic
echo "Iniciando backup com Restic no repositório: $RESTIC_REPO"
restic -r "$RESTIC_REPO" backup "$USER_HOME" --exclude-file="$EXCLUDE_FILE" -vv --tag mths --tag linux_mint

# Depois do backup, sobe os containers novamente
echo "Subindo containers com docker compose..."
docker compose -f "$USER_HOME/.custom/docker-apps/docker-compose.yml" up -d syncthing stirling-pdf

echo "Backup concluído com sucesso!"
