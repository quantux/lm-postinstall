#!/bin/bash

# Etapa 03 - Instala os pacotes apt listados em pacotes_apt.txt

step_03_apt_packages() {
    show_message "Instalando pacotes apt (pacotes_apt.txt)"
    apt-get install -y $(cat pacotes_apt.txt)
}
