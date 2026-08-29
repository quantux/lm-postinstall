#!/bin/bash

# Etapa 25 - Instala a atualização automática do sistema
#
# Um systemd path unit observa /var/lib/apt/lists (via inotify). Toda vez que
# as listas mudam (apt update feito pelo apt-daily.timer), a cadeia de upgrade
# roda: apt update/upgrade/dist-upgrade/autoremove/autoclean, flatpak e spices.
# Guard anti-loop impede re-disparo causado pelo próprio apt update.

step_25_auto_update() {
    show_message "Instalando atualização automática do sistema (auto-upgrade.path)"

    SRC="$SCRIPT_DIR/auto-update"

    install -m 0755 "$SRC/auto-upgrade.sh" /usr/local/sbin/auto-upgrade.sh

    sed -e "s|__USER_NAME__|$USER_NAME|g" \
        -e "s|__USER_UID__|$USER_UID|g" \
        -e "s|__USER_HOME__|$USER_HOME|g" \
        "$SRC/auto-upgrade-chain.sh" > /usr/local/sbin/auto-upgrade-chain.sh
    chmod 0755 /usr/local/sbin/auto-upgrade-chain.sh

    install -m 0644 "$SRC/auto-upgrade.service" /etc/systemd/system/auto-upgrade.service
    install -m 0644 "$SRC/auto-upgrade.path" /etc/systemd/system/auto-upgrade.path
    install -m 0644 "$SRC/auto-upgrade-flatpak.path" /etc/systemd/system/auto-upgrade-flatpak.path

    systemctl daemon-reload
    systemctl enable --now auto-upgrade.path
    systemctl enable --now auto-upgrade-flatpak.path

    # Rede de segurança: mantém ativa a automação diária do próprio Mint.
    mkdir -p /var/lib/linuxmint
    touch /var/lib/linuxmint/mintupdate-automatic-upgrades-enabled

    echo "✔ Auto-upgrade ativo (auto-upgrade.path) — log em /var/log/auto-upgrade.log"
}
