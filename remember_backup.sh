#!/bin/bash

# Diretório do script e arquivo de controle .lock
script_dir=$(dirname "$(realpath "$0")")
backup_lock_file="$script_dir/backup.lock"
current_week=$(date +%U)  # Semana atual do ano
current_day=$(date +%u)   # Dia da semana (1 = Segunda, ..., 7 = Domingo)

# Verifica se o backup já foi feito na semana
backup_feito() {
    [[ -f "$backup_lock_file" && "$(cat "$backup_lock_file")" == "$current_week" ]]
}

# Pergunta ao usuário e executa o backup se necessário
executar_backup() {
    read -p "Você quer fazer o backup do sistema agora? (Y/n) " resposta
    [[ -z "$resposta" || "$resposta" =~ ^[Yy]$ ]] || return

    (
        cd "$script_dir" || exit 1
        ./backup.sh && echo "$current_week" > "$backup_lock_file" && echo "Backup concluído!"
    )
}

# Lógica principal
if backup_feito; then
    echo "O backup já foi feito esta semana."
elif [[ "$current_day" -eq 7 ]]; then
    echo "Hoje é domingo!"
    executar_backup
else
    echo "O backup ainda não foi feito esta semana."
    executar_backup
fi

echo "Processo concluído. Pressione Enter para sair."
read -r
