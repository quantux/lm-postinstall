#!/bin/bash

# Etapa 27 - Instala o certificado do Caddy (Notesnook) na store do sistema,
# para que o navegador confie no servidor local.

step_27_certificado() {
    local cert="$USER_HOME/Dropbox/Áreas/Família/Matheus/Tecnologia/Certificados Digitais/Certificado Notesnook Caddy.crt"

    if [ ! -f "$cert" ]; then
        echo "❌ Certificado não encontrado: $cert" >&2
        return 1
    fi

    show_message "Instalando certificado do Caddy (Notesnook)"
    cp "$cert" /usr/local/share/ca-certificates/
    update-ca-certificates
}
