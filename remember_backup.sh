#!/bin/bash

# Diretório do script e arquivo de controle .lock
script_dir=$(dirname "$(realpath "$0")")
backup_control_file="$script_dir/backup_control_file"
current_month=$(date +%m)  # Mês atual (01-12)
current_day=$(date +%u)    # Dia da semana (1 = Segunda, ..., 7 = Domingo)

# Verifica se o backup já foi feito no mês
backup_feito() {
    [[ -f "$backup_control_file" && "$(cat "$backup_control_file")" == "$current_month" ]]
}

# Pergunta ao usuário e executa o backup se necessário
executar_backup() {
    read -p "Você quer fazer o backup do sistema agora? (Y/n) " resposta
    [[ -z "$resposta" || "$resposta" =~ ^[Yy]$ ]] || return

    (
        cd "$script_dir" || exit 1
        sudo ./backup.sh && echo "$current_month" > "$backup_control_file" && echo "Backup concluído!"
        echo "Processo concluído. Pressione Enter para sair."
        read -r
    )
}

# Lógica principal
if backup_feito; then
    echo "O backup já foi feito este mês."
else
    echo "O backup ainda não foi feito este mês."
    executar_backup
fi
