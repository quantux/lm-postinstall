#!/bin/bash

# Etapa 01 - Restaura o backup do Restic e ajusta o relógio (Windows dualboot)

step_01_restore() {
    timedatectl set-local-rtc 1

    show_message "Restaurando backup Restic diretamente para $USER_HOME..."
    restic -r "$RESTIC_REPO" restore latest --target / --tag mths --tag linux_mint --overwrite
}
