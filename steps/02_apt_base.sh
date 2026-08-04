#!/bin/bash

# Etapa 02 - Configura mirrors, arquitetura 32 bits e base do sistema

step_02_apt_base() {
    show_message "Atualizando mirrors"
    cp /etc/apt/sources.list.d/official-package-repositories.list "$USER_HOME/official-package-repositories.list.bkp"
    sed -i "s/wilma/$LINUXMINT_CODENAME/g; s/noble/$UBUNTU_CODENAME/g" /etc/apt/sources.list.d/official-package-repositories.list

    show_message "Habilitando pacotes de 32 bits"
    dpkg --add-architecture i386

    show_message "Atualizando repositórios"
    apt-get update

    show_message "Atualizando pacotes"
    apt-get upgrade -y
}
