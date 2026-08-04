#!/bin/bash

# Etapa 12 - Instala o Android Studio em /opt

step_12_android_studio() {
    show_message "Instalando Android Studio"
    AS_URL=$(curl -s "https://developer.android.com/studio" | grep -oE 'https://[^" ]*linux\.tar\.gz' | head -1 || true)
    [ -n "$AS_URL" ] || { echo "❌ Falha ao obter o link do Android Studio"; return 1; }
    wget "$AS_URL" -O /tmp/android-studio.tar.gz
    rm -rf /opt/android-studio
    tar -xzf /tmp/android-studio.tar.gz -C /opt
}
