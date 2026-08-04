#!/bin/bash

# Etapa 20 - Restaura configuração personalizada do SSH

step_20_ssh() {
    show_message "Restaurando configuração personalizada do SSH"
    if [ -f "$USER_HOME/.ssh/sshd_custom.conf" ]; then
        cp "$USER_HOME/.ssh/sshd_custom.conf" /etc/ssh/sshd_config.d/sshd_custom.conf
        chmod 644 /etc/ssh/sshd_config.d/sshd_custom.conf
        chown root:root /etc/ssh/sshd_config.d/sshd_custom.conf
    else
        echo "⚠️  $USER_HOME/.ssh/sshd_custom.conf não encontrado no backup; pulando configuração personalizada."
    fi
    systemctl restart ssh
}
