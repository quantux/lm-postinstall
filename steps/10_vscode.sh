#!/bin/bash

# Etapa 10 - Instala o Visual Studio Code a partir do repositório da Microsoft

step_10_vscode() {
    show_message "Instalando VSCode"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /tmp/packages.microsoft.gpg
    install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
    sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    apt-get update
    apt-get install -y code
}
