#!/bin/bash

# Etapa 05 - Codecs e fontes da Microsoft (libdvd-pkg, ttf-mscorefonts)

step_05_codecs() {
    show_message "Instalando libdvd-pkg"
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install libdvd-pkg
    dpkg-reconfigure -f noninteractive libdvd-pkg

    show_message "Instalando ttf-mscorefonts-installer"
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula	boolean	true" | debconf-set-selections
    echo "ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note" | debconf-set-selections
    apt-get install -y ttf-mscorefonts-installer
}
