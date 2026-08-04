#!/bin/bash

# Etapa 15 - Instala o VirtualBox do repositório oficial (compatível com a
# base Ubuntu do Mint atual)

step_15_virtualbox() {
    show_message "Instalando VirtualBox"
    wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc \
        | gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $UBUNTU_CODENAME contrib" \
        > /etc/apt/sources.list.d/virtualbox.list
    apt-get update
    VBOX_PKG="virtualbox-$(curl -s https://download.virtualbox.org/virtualbox/LATEST.TXT | cut -d. -f1-2 || true)"
    if [ -z "$VBOX_PKG" ] || ! apt-cache show "$VBOX_PKG" >/dev/null 2>&1; then
        VBOX_PKG=$(apt-cache search --names-only '^virtualbox-[0-9]' | awk '{print $1}' | sort -V | tail -1 || true)
    fi
    [ -n "$VBOX_PKG" ] || { echo "❌ Falha ao obter o pacote do VirtualBox"; return 1; }
    apt-get install -y "$VBOX_PKG"
}
