#!/bin/bash

# Etapa 16 - Instala o Google Antigravity IDE e CLI

step_16_antigravity() {
    show_message "Instalando Google Antigravity IDE"

    IDE_HTML=$(curl -s -A "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "https://antigravity.google/download" 2>/dev/null | tr -d '\0' || true)
    IDE_URL=$(echo "$IDE_HTML" | grep -oE 'https://edgedl\.me\.gvt1\.com/edgedl/release2/[^"]*Antigravity%20IDE\.tar\.gz' | head -1 || true)
    [ -z "$IDE_URL" ] && IDE_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz"

    wget "$IDE_URL" -O /tmp/antigravity-ide.tar.gz
    mkdir -p "/opt/Antigravity IDE"
    mkdir -p /tmp/antigravity-ide-extracted
    tar -xzf /tmp/antigravity-ide.tar.gz -C /tmp/antigravity-ide-extracted
    EXTRACT_DIR=$(find /tmp/antigravity-ide-extracted -maxdepth 1 -type d -name "Antigravity IDE*" | head -1)
    if [ -n "$EXTRACT_DIR" ]; then
        cp -r "$EXTRACT_DIR"/* "/opt/Antigravity IDE/"
    else
        echo "❌ Falha ao encontrar o diretório extraído do Antigravity IDE"
        rm -rf /tmp/antigravity-ide*
        return 1
    fi
    rm -rf /tmp/antigravity-ide*

    show_message "Instalando Google Antigravity CLI"
    CLI_URL=$(echo "$IDE_HTML" | grep -oE 'https://antigravity\.google/cli/install\.sh' | head -1 || true)
    [ -z "$CLI_URL" ] && CLI_URL="https://antigravity.google/cli/install.sh"
    user_do "curl -fsSL '$CLI_URL' | bash" || echo "⚠️  Falha ao instalar CLI, continuando..."
}
