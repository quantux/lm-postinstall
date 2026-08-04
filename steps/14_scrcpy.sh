#!/bin/bash

# Etapa 14 - Instala o scrcpy (binários em /usr/local/bin)

step_14_scrcpy() {
    show_message "Instalando scrcpy"
    local API_URL="https://api.github.com/repos/Genymobile/scrcpy/releases/latest"
    local SCRCPY_URL TAG

    TAG=$(curl -s --retry 3 --retry-delay 2 "$API_URL" \
        | grep -oE '"tag_name": "[^"]*"' | cut -d'"' -f4 || true)
    SCRCPY_URL=$(curl -s --retry 3 --retry-delay 2 "$API_URL" \
        | grep -oE '"browser_download_url": "[^"]*linux-x86_64[^"]*\.tar\.gz"' | cut -d'"' -f4 || true)

    # Fallback: monta o link diretamente a partir da tag
    if [ -z "$SCRCPY_URL" ] && [ -n "$TAG" ]; then
        SCRCPY_URL="https://github.com/Genymobile/scrcpy/releases/download/$TAG/scrcpy-linux-x86_64-$TAG.tar.gz"
    fi

    [ -n "$SCRCPY_URL" ] || { echo "❌ Falha ao obter o link do scrcpy"; return 1; }
    wget -q --show-progress "$SCRCPY_URL" -O /tmp/scrcpy.tar.gz
    rm -rf /tmp/scrcpy
    mkdir -p /tmp/scrcpy
    tar -xzf /tmp/scrcpy.tar.gz -C /tmp/scrcpy --strip-components=1
    [ -x /tmp/scrcpy/scrcpy ] || { echo "❌ Binário scrcpy não encontrado no pacote"; return 1; }
    install -m 755 /tmp/scrcpy/scrcpy /usr/local/bin/scrcpy
    install -m 755 /tmp/scrcpy/scrcpy-server /usr/local/bin/scrcpy-server
}
