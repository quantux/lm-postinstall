#!/bin/bash

# Etapa 09 - Instala e atualiza pacotes Flatpak (pacotes_flatpak.txt)

step_09_flatpak() {
    show_message "Instalando pacotes flatpak"
    flatpak install -y --noninteractive flathub $(cat pacotes_flatpak.txt)

    show_message "Atualizando pacotes flatpak"
    flatpak update -y
}
