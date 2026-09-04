#!/bin/bash
set -u

# Executado como root pelo auto-upgrade.sh. Sem "sudo" (ja e root).
# Os valores __USER_* sao substituidos na instalacao (steps/25_auto_update.sh).

# Always-Include-Phased-Updates: o tray mostra updates em phasing (rollout
# gradual do Ubuntu) como disponiveis; sem esta opcao o apt os adia para sempre.
APT_OPTS="-o APT::Acquire::LockTimeout=300 -o Acquire::Retries=3 -o Acquire::http::Timeout=60 -o Acquire::https::Timeout=60 -o APT::Get::Always-Include-Phased-Updates=true"

# Re-tenta ate 3x com pausa: cobre falhas transitorias de rede/DNS e lock.
apt_retry() {
  local i
  for i in 1 2 3; do
    if apt-get "$@" $APT_OPTS; then
      return 0
    fi
    echo "== apt-get $* falhou (tentativa ${i}/3); aguardando 60s..."
    sleep 60
  done
  echo "== apt-get $* falhou apos 3 tentativas."
  return 1
}

apt_retry update
apt_retry upgrade -y
apt_retry dist-upgrade -y
apt_retry autoremove -y || true
apt_retry autoclean -y || true

flatpak update -y

# Flatpaks instalados por-usuario (o flatpak update como root nao os ve).
runuser -u __USER_NAME__ -- flatpak update -y --user || true

# O daemon do Update Manager (tray) nao detecta instalacoes de flatpak feitas
# por fora do proprio mintupdate, deixando o icone obsoleto. Se havia flatpak
# pendente (acabou de instalar), reinicia o daemon para limpar o estado.
fp_pending=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
if [ "$fp_pending" -gt 0 ]; then
  echo "Flatpaks atualizados; reiniciando o tray do Update Manager para limpar o estado."
  pkill -f "mintUpdate.py" 2>/dev/null
  sleep 1
  sudo -u __USER_NAME__ env DISPLAY=:0 XAUTHORITY=__USER_HOME__/.Xauthority \
    DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/__USER_UID__/bus XDG_RUNTIME_DIR=/run/user/__USER_UID__ \
    setsid /usr/lib/linuxmint/mintUpdate/mintUpdate.py </dev/null >/dev/null 2>&1 &
fi

# Spices sao por-usuario e precisam da sessao grafica; roda como o usuario logado.
runuser -u __USER_NAME__ -- env DISPLAY=:0 XAUTHORITY=__USER_HOME__/.Xauthority \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/__USER_UID__/bus XDG_RUNTIME_DIR=/run/user/__USER_UID__ \
  /usr/bin/cinnamon-spice-updater --update-all

exit 0
