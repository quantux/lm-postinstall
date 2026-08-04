#!/bin/bash

# Etapa 18 - Configurações do ambiente desktop

step_18_desktop_env() {
    show_message "Definindo qBittorrent como app padrão para links magnet"
    user_do "xdg-mime default org.qbittorrent.qBittorrent.desktop x-scheme-handler/magnet"

    show_message "Permitindo jogos em tela cheia"
    if ! grep -q '^SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0$' /etc/environment; then
        echo "SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0" >> /etc/environment
    fi
}
