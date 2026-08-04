#!/bin/bash

# Etapa 07 - Temas e ícones (Adapta Nokto, Flat Remix, La-Capitaine)

step_07_themes() {
    show_message "Instalando Adapta Nokto"
    tar -xf ./assets/themes/Adapta-Nokto.tar.xz -C /usr/share/themes

    show_message "Instalando Flat Remix theme"
    tar -xf ./assets/themes/Flat-Remix-GTK-Blue-Darkest-Solid-NoBorder.tar.xz -C /usr/share/themes

    show_message "Instalando ícones La-Capitaine"
    tar -xf ./assets/icons/la-capitaine.tar.xz -C /usr/share/icons/
}
