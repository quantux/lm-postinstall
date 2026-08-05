#!/bin/bash

# Etapa 23 - Remove pastas padrão do usuário que estejam vazias
# (Área de trabalho, Documentos, Modelos, Músicas, Público)

step_23_cleanup() {
    show_message "Removendo pastas padrão do usuário que estejam vazias"
    for dir in "Área de trabalho" "Documentos" "Modelos" "Músicas" "Público"; do
        path="$USER_HOME/$dir"
        if [ -d "$path" ] && [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
            if rmdir "$path" 2>/dev/null; then
                echo "✔ Removida (estava vazia): $dir"
            fi
        fi
    done
}
