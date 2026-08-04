#!/bin/bash

# Etapa 11 - Instala o Neovim em /opt/nvim

step_11_nvim() {
    show_message "Instalando nvim"
    curl -L -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    rm -rf /opt/nvim
    tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
}
