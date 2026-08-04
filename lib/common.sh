#!/bin/bash

# Helpers e infraestrutura compartilhada pelos scripts.
# Define variáveis globais, funções utilitárias e o mecanismo de
# idempotência baseado em marcadores em ~/.postinstall.

POSTINSTALL_DIR="$USER_HOME/.postinstall"
POSTINSTALL_STEPS="$POSTINSTALL_DIR/steps"
POSTINSTALL_LOG="$POSTINSTALL_DIR/recover.log"

show_message() {
    printf '%0.s-' {1..45}; echo
    printf "%s\n\n" "$1"
}

# Executa um comando como o usuário real (não-root) em shell de login.
user_do() {
    sudo -u "$USER_NAME" bash -l -c "$1"
}

# Registra uma linha no log de execução.
log_line() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$POSTINSTALL_LOG"
}

# Inicializa a infraestrutura de idempotência.
init_postinstall() {
    mkdir -p "$POSTINSTALL_STEPS"
    touch "$POSTINSTALL_LOG"
}

# Marca uma etapa como concluída.
mark_step() {
    local name="$1"
    touch "$POSTINSTALL_STEPS/$name"
}

# Verifica se uma etapa já foi concluída.
step_done() {
    local name="$1"
    [ -f "$POSTINSTALL_STEPS/$name" ]
}

# Executa uma função apenas se a etapa ainda não foi concluída.
# A etapa roda num subshell com `set -e` (como no script original), então o
# primeiro erro aborta a etapa; a falha é capturada e reportada sem derrubar
# o orquestrador.
# Uso: run_step <nome> <função>
# Retorna 0 se executou (ou já estava concluída), 1 se falhou.
run_step() {
    local name="$1" func="$2"

    if step_done "$name"; then
        show_message "⏭️  Etapa '$name' já concluída anteriormente. Pulando."
        return 0
    fi

    log_line "==> iniciando etapa: $name"
    show_message "▶ Executando etapa: $name"

    if ( set -e; "$func" ); then
        mark_step "$name"
        log_line "==> etapa concluída: $name"
        return 0
    else
        log_line "==> etapa FALHOU: $name"
        echo "❌ A etapa '$name' falhou. Corrija o problema e reexecute o script." >&2
        return 1
    fi
}

# Remove um marcador, permitindo reexecutar uma etapa.
unmark_step() {
    local name="$1"
    rm -f "$POSTINSTALL_STEPS/$name"
}

# Remove todos os marcadores, forçando a reexecução de tudo.
reset_steps() {
    rm -rf "$POSTINSTALL_STEPS"
    echo "Marcadores de etapas removidos de $POSTINSTALL_STEPS"
}

# Lista as etapas concluídas e pendentes.
status_steps() {
    local step
    echo "Etapas registradas em $POSTINSTALL_STEPS:"
    for step in "$POSTINSTALL_STEPS"/*; do
        [ -e "$step" ] || continue
        echo "  ✔ $(basename "$step")"
    done
    echo "Para limpar os marcadores: $0 --reset"
}
