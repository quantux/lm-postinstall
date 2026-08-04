#!/bin/bash

# Etapa 17 - Instala TeamViewer e oh-my-posh

step_17_teamviewer_ohmyposh() {
    show_message "Instalando TeamViewer"
    wget "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" -O /tmp/teamviewer.deb
    dpkg -i /tmp/teamviewer.deb || true
    apt-get install -fy

    show_message "Instalando oh-my-posh"
    wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
    chmod +x /usr/local/bin/oh-my-posh
}
