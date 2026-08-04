#!/bin/bash

# Etapa 22 - Define o zsh como shell padrão do usuário

step_22_shell() {
    show_message "Definir zsh como shell padrão"
    chsh -s "$(which zsh)" "$USER_NAME"
}
