#!/bin/bash

# Etapa 03 - Instala os pacotes apt listados em pacotes_apt.txt

step_03_apt_packages() {
    show_message "Instalando pacotes apt (pacotes_apt.txt)"
    # Aceita rodar o iperf3 como daemon sem confirmar durante a instalação
    echo "iperf3 iperf3/start_daemon boolean true" | debconf-set-selections
    apt-get install -y $(cat pacotes_apt.txt)
}
