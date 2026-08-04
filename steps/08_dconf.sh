#!/bin/bash

# Etapa 08 - Carrega configurações do dconf e atualiza o tldr

step_08_dconf() {
    show_message "Carregando configurações do dconf"
    user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${USER_UID}/bus' dconf load / < $USER_HOME/.dconf/dconf" || true

    show_message "Atualizando tldr"
    user_do "tldr --update" || true
}
