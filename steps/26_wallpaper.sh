#!/bin/bash

# Etapa 26 - Reaplica o wallpaper que estava em uso no último backup.
# A imagem em si já é restaurada pelo restic (etapa 01); aqui só redefinimos
# a escolha registrada pelo backup.sh.

step_26_wallpaper() {
    local state="$USER_HOME/.config/lm-postinstall/wallpaper"

    if [ ! -s "$state" ]; then
        show_message "⚠️  Nenhum wallpaper registrado no último backup. Pulando."
        return 0
    fi

    local uri
    uri=$(cat "$state")
    uri="${uri%\'}"
    uri="${uri#\'}"

    show_message "Restaurando wallpaper do último backup: $uri"
    user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${USER_UID}/bus' gsettings set org.cinnamon.desktop.background picture-uri '$uri'"
}
