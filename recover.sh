#!/bin/bash

# Verifica se o sudo está instalado
if ! command -v sudo >/dev/null 2>&1; then
    echo "❌ O sudo não está instalado. Este script precisa do sudo."
    exit 1
fi

# Verifica se o script está sendo executado via sudo
if [ -z "$SUDO_USER" ]; then
    echo "❌ Execute este script usando sudo: sudo $0"
    exit 1
fi

# Global
USER_NAME="$SUDO_USER"
USER_UID=$(id -u "$USER_NAME")
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
LINUXMINT_CODENAME=$(grep CODENAME /etc/linuxmint/info | cut -d= -f2)
UBUNTU_CODENAME=$(grep DISTRIB_CODENAME /etc/upstream-release/lsb-release | cut -d= -f2)
DOCKER_COMPOSE_PATH="$USER_HOME/.scripts/docker-apps/docker-compose.yml"
RESTIC_REPO="/media/restic/restic_notebook_repo"

# Testa se o repositório existe
if [ ! -d "$RESTIC_REPO" ]; then
  echo "O caminho $RESTIC_REPO não existe."
  exit 1
fi

# Testa se o restic está instalado
if command -v restic >/dev/null 2>&1; then
    echo "✅ Restic está instalado."
    restic version
else
    echo "❌ Restic não está instalado."
    exit 1
fi

show_message() {
	printf '%0.s-' {1..45}; echo
	printf "%s\n\n" "$1"
}

user_do() {
    sudo -u "$USER_NAME" bash -l -c "$1"
}

# Fix clock time for windows dualboot
timedatectl set-local-rtc 1

# Restaurar diretamente para a home
show_message "Restaurando backup Restic diretamente para $USER_HOME..."
restic -r "$RESTIC_REPO" restore latest --target / --tag mths --tag linux_mint

# Set mirrors
show_message "Atualizando mirrors"
cp /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/official-package-repositories.list.bkp
sed -i "s/wilma/$LINUXMINT_CODENAME/g; s/noble/$UBUNTU_CODENAME/g" /etc/apt/sources.list.d/official-package-repositories.list

# 32bits packages
show_message "Habilitando pacotes de 32 bits"
dpkg --add-architecture i386

# Update
show_message "Atualizando repositórios"
apt-get update

# Upgrade
show_message "Atualizando pacotes"
apt-get upgrade -y

# Install apt-get packages
show_message "Instalando pacotes"
apt-get install -y $(cat pacotes_apt.txt)

# Nvidia Container Toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get install -y nvidia-cuda-toolkit nvidia-container-toolkit

# Instalando libdvd-pkg
show_message "Instalando libdvd-pkg"
export DEBIAN_FRONTEND=noninteractive
apt-get -y install libdvd-pkg
dpkg-reconfigure -f noninteractive libdvd-pkg

# Install ttf-mscorefonts-installer
show_message "Instalando ttf-mscorefonts-installer"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula	boolean	true" | debconf-set-selections
echo "ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note" | debconf-set-selections
apt-get install -y ttf-mscorefonts-installer

# Install - Roboto and Noto Sans Fonts
show_message "Instalando fontes Roboto e Noto Sans"
wget "https://fonts.google.com/download?family=Roboto" -O /tmp/roboto.zip
wget "https://fonts.google.com/download?family=Noto Sans" -O /tmp/noto_sans.zip
unzip /tmp/roboto.zip -d /usr/share/fonts/
unzip /tmp/noto_sans.zip -d /usr/share/fonts/

# Install NerdFront Firacode
show_message "Instalando fontes NerdFont Firacode"
wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/FiraCode.zip" -O /tmp/firacode.zip
unzip /tmp/firacode.zip -d /usr/share/fonts/

# Install - Adapta Nokto theme
show_message "Instalando Adapta Nokto"
tar -xf ./assets/themes/Adapta-Nokto.tar.xz -C /usr/share/themes

# Install Flat Remix theme
show_message "Instalando Flat Remix theme"
tar -xf ./assets/themes/Flat-Remix-GTK-Blue-Darkest-Solid-NoBorder.tar.xz -C /usr/share/themes

# La-Capitaine Icons
show_message "Instalando ícones La-Capitaine"
tar -xf ./assets/icons/la-capitaine.tar.xz -C /usr/share/icons/

# WPS Office Fonts
show_message "Instalando fontes para o WPS Office"
git clone https://github.com/udoyen/wps-fonts.git /tmp/wps-fonts
mv /tmp/wps-fonts/wps /usr/share/fonts/

# Load dconf file
show_message "Carregando configurações do dconf"
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${USER_UID}/bus' dconf load / < $USER_HOME/.dconf/dconf"

# Update tldr
user_do "tldr --update"

# Instalando virtualbox-guest-x11
show_message "Instalando virtualbox-guest-x11"
yes Y | apt-get install -y virtualbox-guest-x11

# Install flatpak packages
show_message "Instalando pacotes flatpak"
flatpak install -y --noninteractive flathub $(cat pacotes_flatpak.txt)

# Update flatpak
show_message "Atualizando pacotes flatpak"
flatpak update -y

# Install VSCode
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -D -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/packages.microsoft.gpg
sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
apt update
apt install -y code

# Install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
rm -rf /opt/nvim
tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Install Android Studio
show_message "Instalando Android Studio"
wget "https://edgedl.me.gvt1.com/android/studio/ide-zips/2026.1.3.7/android-studio-quail3-linux.tar.gz" -O /tmp/android-studio.tar.gz
rm -rf /opt/android-studio
tar -xzf /tmp/android-studio.tar.gz -C /opt

# Install Android SDK (tools + platforms + emulator) in ~/Android/Sdk
show_message "Instalando Android SDK em $ANDROID_HOME"
ANDROID_HOME="$USER_HOME/Android/Sdk"
ANDROID_JAVA_HOME="/opt/android-studio/jbr"
SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

# Download the latest command-line tools (version resolved dynamically from Google's repo)
mkdir -p /tmp/cmdline-tools-extract
LATEST_CMDLINE=$(curl -s "https://dl.google.com/android/repository/repository2-3.xml" \
    | grep -oE 'commandlinetools-linux-[0-9]+_latest\.zip' | sort -u -t- -k3 -n | tail -1)
wget "https://dl.google.com/android/repository/$LATEST_CMDLINE" -O /tmp/cmdline-tools.zip
unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract
mkdir -p "$ANDROID_HOME/cmdline-tools"
rm -rf "$ANDROID_HOME/cmdline-tools/latest"
mv /tmp/cmdline-tools-extract/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
chown -R "$USER_NAME:$USER_NAME" "$ANDROID_HOME"

# Accept licenses (as user, using the Java bundled with Android Studio)
user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && yes | $SDKMANAGER --licenses >/dev/null 2>&1"

# Resolve packages dynamically from what sdkmanager offers (stable channel)
SDK_LIST=$(user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && $SDKMANAGER --list")

# Last two major Android versions (e.g. 37 and 36)
PLAT_LINES=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '
    /^  platforms;android-/ {
        p=$1; gsub(/^ +| +$/,"",p); sub(/^platforms;android-/,"",p);
        if (p ~ /(-beta|-rc|-alpha|-canary)/) next;
        m=p; sub(/-.*|\..*/,"",m);
        print m, p
    }' | sort -u -k2)
TOP_MAJORS=$(printf '%s\n' "$PLAT_LINES" | awk '{print $1}' | sort -un | tail -2)

# Assemble the package list
SDK_PACKAGES=()
for m in $TOP_MAJORS; do
    while read -r M P; do
        [ "$M" = "$m" ] || continue
        SDK_PACKAGES+=("platforms;android-$P")
        [[ "$P" != *-ext* ]] && SDK_PACKAGES+=("sources;android-$P")
    done <<< "$PLAT_LINES"
done
for m in $TOP_MAJORS; do
    while read -r M V; do
        [ "$M" = "$m" ] && SDK_PACKAGES+=("build-tools;$V")
    done <<< "$(printf '%s\n' "$SDK_LIST" | awk -F'|' '
        /^  build-tools;/ {
            v=$1; gsub(/^ +| +$/,"",v); sub(/^build-tools;/,"",v);
            if (v ~ /-rc|-beta/) next;
            m=v; sub(/\..*/,"",m); print m, v
        }' | sort -V -k2)"
done

LATEST_NDK=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '/^  ndk;/{gsub(/^ +| +$/,"",$1); sub(/^ndk;/,"",$1); if($1 ~ /-/) next; print $1}' | sort -V | tail -1)
LATEST_CMAKE=$(printf '%s\n' "$SDK_LIST" | awk -F'|' '/^  cmake;/{gsub(/^ +| +$/,"",$1); sub(/^cmake;/,"",$1); print $1}' | sort -V | tail -1)

SDK_PACKAGES+=(
    "platform-tools"
    "emulator"
    "cmdline-tools;latest"
    "ndk;$LATEST_NDK"
    "cmake;$LATEST_CMAKE"
    "extras;android;m2repository"
    "extras;google;m2repository"
)

# Install everything (as user)
user_do "export JAVA_HOME=$ANDROID_JAVA_HOME && yes | $SDKMANAGER ${SDK_PACKAGES[*]}"

echo "ANDROID_HOME=$ANDROID_HOME" >> /etc/environment
echo "ANDROID_SDK_ROOT=$ANDROID_HOME" >> /etc/environment

# Install scrcpy
show_message "Instalando scrcpy"
SCRCPY_URL=$(curl -s "https://api.github.com/repos/Genymobile/scrcpy/releases/latest" \
    | grep -oE '"browser_download_url": "[^"]*linux-x86_64[^"]*\.tar\.gz"' | cut -d'"' -f4)
wget "$SCRCPY_URL" -O /tmp/scrcpy.tar.gz
rm -rf /tmp/scrcpy
mkdir -p /tmp/scrcpy
tar -xzf /tmp/scrcpy.tar.gz -C /tmp/scrcpy --strip-components=1
install -m 755 /tmp/scrcpy/scrcpy /usr/local/bin/scrcpy
install -m 755 /tmp/scrcpy/scrcpy_server /usr/local/bin/scrcpy_server

# Install VirtualBox from virtualbox.org (latest compatible with the Ubuntu base of this Mint)
show_message "Instalando VirtualBox"
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc \
    | gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $UBUNTU_CODENAME contrib" \
    > /etc/apt/sources.list.d/virtualbox.list
apt-get update
VBOX_PKG="virtualbox-$(curl -s https://download.virtualbox.org/virtualbox/LATEST.TXT | cut -d. -f1-2)"
if ! apt-cache show "$VBOX_PKG" >/dev/null 2>&1; then
    VBOX_PKG=$(apt-cache search --names-only '^virtualbox-[0-9]' | awk '{print $1}' | sort -V | tail -1)
fi
apt-get install -y "$VBOX_PKG"

# Install Teamviewer
show_message "Instalando TeamViewer"
wget "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" -O /tmp/teamviewer.deb
dpkg -i /tmp/teamviewer.deb
apt install -fy

# Install oh-my-posh
show_message "Instalando oh-my-posh"
wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
chmod +x /usr/local/bin/oh-my-posh

# Set qBitTorrent as default magnet link app
xdg-mime default org.qbittorrent.qBittorrent.desktop x-scheme-handler/magnet

# Allow games run in fullscreen mode
echo "SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0" >> /etc/environment

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Restore custom SSH config
cp "$USER_HOME/.ssh/sshd_custom.conf" /etc/ssh/sshd_config.d/sshd_custom.conf
chmod 644 /etc/ssh/sshd_config.d/sshd_custom.conf
chown root:root /etc/ssh/sshd_config.d/sshd_custom.conf
systemctl restart ssh

# Install Docker
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do apt-get remove $pkg; done
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to groups
usermod -aG docker,vboxusers,kvm,libvirt "$USER_NAME"

# Start containers
docker compose -f "$DOCKER_COMPOSE_PATH" up -d

# Define zsh como shell padrão
show_message "Definir zsh como shell padrão"
chsh -s $(which zsh) $USER_NAME
user_do "chsh -s $(which zsh)"

# Reiniciar
show_message ""
while true; do
    read -p "Finalizado! Deseja reiniciar? (y/n): " yn
    case $yn in
        [Yy]* ) reboot; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
