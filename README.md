# lm-postinstall

Scripts de backup e restauração pós-instalação do Linux Mint.

## Estrutura

- `recover.sh` — orquestrador da restauração pós-instalação
- `backup.sh` — backup do sistema (restic + dconf + docker)
- `remember_backup.sh` — lembrete mensal de backup
- `steps/` — etapas modulares da restauração (`XX_nome.sh`)
- `auto-update/` — templates da atualização automática (instalados na etapa 25)
- `lib/common.sh` — helpers compartilhados e infraestrutura de idempotência
- `pacotes_apt.txt` — lista de pacotes apt
- `pacotes_flatpak.txt` — lista de pacotes flatpak
- `assets/` — temas e ícones
- `ignore-files` — regras de exclusão do restic

## Restaurar

1. Instalar:
   - `sudo apt-get install -y git restic`
2. Montar o repositório do restic em `/media/restic/restic_notebook_repo`
3. Executar `sudo ./recover.sh`

## Idempotência

Cada etapa em `steps/` só roda uma vez: ao concluir com sucesso, um marcador é
criado em `~/.postinstall/steps/`. Em execuções seguintes, as etapas concluídas
são puladas, então o script pode ser reexecutado com segurança.

| Comando                  | Efeito                                        |
| ------------------------ | --------------------------------------------- |
| `sudo ./recover.sh`      | Executa apenas as etapas ainda pendentes      |
| `./recover.sh --status`  | Lista etapas já concluídas                    |
| `./recover.sh --reset`   | Remove os marcadores (refaz tudo na próxima)  |

O log de execução fica em `~/.postinstall/recover.log`.

## Backup

Executar `sudo ./backup.sh` ou usar o lembrete mensal `./remember_backup.sh`.
