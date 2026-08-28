#!/bin/bash
set -u

# Executado como root pelo auto-upgrade.sh. Sem "sudo" (ja e root).
# Os valores __USER_* sao substituidos na instalacao (steps/25_auto_update.sh).
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y
flatpak update -y

# Spices sao por-usuario e precisam da sessao grafica; roda como o usuario logado.
runuser -u __USER_NAME__ -- env DISPLAY=:0 XAUTHORITY=__USER_HOME__/.Xauthority \
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/__USER_UID__/bus XDG_RUNTIME_DIR=/run/user/__USER_UID__ \
  /usr/bin/cinnamon-spice-updater --update-all

exit 0
