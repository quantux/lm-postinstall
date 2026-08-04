#!/bin/bash

# Etapa 14 - Instala o scrcpy (binários em /usr/local/bin)

step_14_scrcpy() {
    show_message "Instalando scrcpy"
    SCRCPY_URL=$(curl -s "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" \
        | grep -oE '"browser_download_url": "[^"]*linux-x86_64[^"]*\.tar\.gz"' | cut -d'"' -f4 || true)
    [ -n "$SCRCPY_URL" ] || { echo "❌ Falha ao obter o link do scrcpy"; return 1; }
    wget "$SCRCPY_URL" -O /tmp/scrcpy.tar.gz
    rm -rf /tmp/scrcpy
    mkdir -p /tmp/scrcpy
    tar -xzf /tmp/scrcpy.tar.gz -C /tmp/scrcpy --strip-components=1
    install -m 755 /tmp/scrcpy/scrcpy /usr/local/bin/scrcpy
    install -m 755 /tmp/scrcpy/scrcpy_server /usr/local/bin/scrcpy_server
}
