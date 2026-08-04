#!/bin/bash

# Etapa 06 - Fontes: Roboto, Noto Sans, NerdFont FiraCode e fontes do WPS Office

step_06_fonts() {
    show_message "Instalando fontes Roboto e Noto Sans"
    wget "https://fonts.google.com/download?family=Roboto" -O /tmp/roboto.zip || true
    wget "https://fonts.google.com/download?family=Noto Sans" -O /tmp/noto_sans.zip || true
    unzip -q /tmp/roboto.zip -d /usr/share/fonts/ 2>/dev/null || true
    unzip -q /tmp/noto_sans.zip -d /usr/share/fonts/ 2>/dev/null || true

    show_message "Instalando fontes NerdFont Firacode"
    FIRACODE_URL=$(curl -s "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" \
        | grep -oE '"browser_download_url": "[^"]*FiraCode\.zip"' | cut -d'"' -f4 || true)
    [ -n "$FIRACODE_URL" ] || { echo "❌ Falha ao obter o link do FiraCode"; return 1; }
    wget "$FIRACODE_URL" -O /tmp/firacode.zip
    unzip -q /tmp/firacode.zip -d /usr/share/fonts/

    show_message "Instalando fontes para o WPS Office"
    git clone https://github.com/udoyen/wps-fonts.git /tmp/wps-fonts
    mv /tmp/wps-fonts/wps /usr/share/fonts/
}
