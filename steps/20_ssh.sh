#!/bin/bash

# Etapa 20 - Restaura configuração personalizada do SSH

step_20_ssh() {
    show_message "Restaurando configuração personalizada do SSH"
    cp "$USER_HOME/.ssh/sshd_custom.conf" /etc/ssh/sshd_config.d/sshd_custom.conf
    chmod 644 /etc/ssh/sshd_config.d/sshd_custom.conf
    chown root:root /etc/ssh/sshd_config.d/sshd_custom.conf
    systemctl restart ssh
}
