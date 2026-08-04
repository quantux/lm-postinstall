#!/bin/bash

# Etapa 19 - Instala o Tailscale

step_19_tailscale() {
    show_message "Instalando Tailscale"
    curl -fsSL https://tailscale.com/install.sh | sh
}
