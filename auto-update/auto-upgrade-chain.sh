#!/bin/bash
set -u

# Executado como root pelo auto-upgrade.sh. Sem "sudo" (ja e root).
# Os valores __USER_* sao substituidos na instalacao (steps/25_auto_update.sh).
apt-get update -o APT::Acquire::LockTimeout=300
apt-get upgrade -y -o APT::Acquire::LockTimeout=300
apt-get dist-upgrade -y -o APT::Acquire::LockTimeout=300
apt-get autoremove -y -o APT::Acquire::LockTimeout=300
apt-get autoclean -y -o APT::Acquire::LockTimeout=300
flatpak update -y

# Flatpaks instalados por-usuario (o flatpak update como root nao os ve).
runuser -u __USER_NAME__ -- flatpak update -y --user || true

# Spices sao por-usuario e precisam da sessao grafica; roda como o usuario logado.
runuser -u __USER_NAME__ -- env DISPLAY=:0 XAUTHORITY=__USER_HOME__/.Xauthority \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/__USER_UID__/bus XDG_RUNTIME_DIR=/run/user/__USER_UID__ \
  /usr/bin/cinnamon-spice-updater --update-all

exit 0
