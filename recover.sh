#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Global
USER_NAME="${SUDO_USER:-$LOGNAME}"
USER_UID=$(id -u ${USER_NAME})
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
LINUXMINT_CODENAME=$(grep CODENAME /etc/linuxmint/info | cut -d= -f2)
UBUNTU_CODENAME=$(cat /etc/upstream-release/lsb-release | grep DISTRIB_CODENAME= | cut -f2 -d "=")
RESTIC_REPO="rclone:gdrive:/restic_repo"
DOCKER_COMPOSE_PATH="$USER_HOME/.scripts/docker-apps/docker-compose.yml"

RESTIC_REPO="/media/restic/restic_repo"
echo "O repositório restic deve estar em $RESTIC_REPO"

# Perguntar onde restaurar o backup
echo "De onde deseja restaurar o backup Restic?"
echo "1) Local ($USER_HOME/restic/restic_repo)"
echo "2) Nuvem (Google Drive via rclone)"
read -rp "Escolha 1 ou 2: " choice

case "$choice" in
  1)
    LOCAL_PATH="$USER_HOME/restic/restic_repo"
    if [ ! -d "$LOCAL_PATH" ]; then
      echo "O caminho $LOCAL_PATH não existe. Saindo..."
      exit 1
    fi
    RESTIC_REPO="$LOCAL_PATH"
    ;;
  2)
    RESTIC_REPO="rclone:gdrive:/restic_repo"
    ;;
  *)
    echo "Opção inválida. Saindo..."
    exit 1
    ;;
esac

show_message() {
	printf '%0.s-' {1..45}; echo
	printf "%s\n\n" "$1"
}

user_do() {
    su - "$USER_NAME" -c "$SHELL --login -c '$1'"
}

# Fix clock time for windows dualboot
timedatectl set-local-rtc 1

# Restaurar diretamente para a home
show_message "Restaurando backup Restic diretamente para $USER_HOME..."
restic -r "$RESTIC_REPO" restore latest --target "$USER_HOME" --tag mths --tag linux_mint

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
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

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
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${USER_UID}/bus' dconf load / < /$USER_HOME/.dconf/dconf"

# Update tldr
user_do "tldr --update"

# Instalando virtualbox-guest-x11
show_message "Instalando virtualbox-guest-x11"
yes Y | apt-get install -y virtualbox-guest-x11

# Add user to vbox group
usermod -aG vboxusers $USER_NAME

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
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

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

# Docker
# Remove pacotes antigos relacionados ao Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    apt-get remove -y "$pkg"
done

# Cria diretório para chave GPG do Docker
install -m 0755 -d /etc/apt/keyrings

# Baixa a chave GPG do Docker
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Adiciona o repositório oficial do Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
> /etc/apt/sources.list.d/docker.list

# Atualiza repositórios e instala pacotes Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Adiciona usuário ao grupo docker
usermod -aG docker "${SUDO_USER:-$USER}"

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
