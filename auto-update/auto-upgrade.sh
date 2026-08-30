#!/bin/bash
set -u

LOG=/var/log/auto-upgrade.log
STAMP=/run/auto-upgrade.last
LOCK=/run/auto-upgrade.lock
DEBOUNCE=120

log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

# Guarda contra loop: o proprio "apt-get update" da cadeia reescreve as listas
# (e cria/remove o lock), o que re-dispara este unit. Disparos dentro da janela
# so sao ignorados se nao houver nada pendente (apt ou flatpak) - assim uma
# descoberta de atualizacao logo apos uma execucao nunca e perdida.
now=$(date +%s)
last=0
[ -f "$STAMP" ] && last=$(cat "$STAMP" 2>/dev/null || echo 0)
if [ $(( now - last )) -lt "$DEBOUNCE" ]; then
  pending_apt=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst ")
  pending_flatpak=$(timeout 25 flatpak remote-ls --updates 2>/dev/null | grep -c .)
  if [ $(( pending_apt + pending_flatpak )) -eq 0 ]; then
    log "Sem atualizacoes pendentes; disparo repetido ignorado (janela ${DEBOUNCE}s)."
    exit 0
  fi
  log "Disparo dentro da janela mas com ${pending_apt} apt + ${pending_flatpak} flatpak pendentes; executando."
fi
echo "$now" > "$STAMP"

# Nunca duas cadeias ao mesmo tempo (ex.: coincidir com apt-daily.timer).
exec 9>"$LOCK"
flock -n 9 || { log "Outra execucao em andamento; ignorando."; exit 0; }

# Se notebook desplugado, espera a tomada (mesma regra da automacao do Mint).
if [ -r /sys/class/power_supply/AC/online ] && [ "$(cat /sys/class/power_supply/AC/online)" != "1" ]; then
  log "Na bateria; abortando."
  exit 0
fi

log "Listas de pacotes mudaram; executando cadeia de upgrade."
systemd-inhibit --why="Atualizacao automatica" --who="auto-upgrade" \
  --what=shutdown --mode=block /usr/local/sbin/auto-upgrade-chain.sh >> "$LOG" 2>&1
status=$?
log "Cadeia concluida (exit=$status)."
exit "$status"
