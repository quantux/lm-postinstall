#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Terminal colors
LightColor='\033[1;32m'
NC='\033[0m'

# Vars
REGULAR_USER_NAME="${SUDO_USER:-$LOGNAME}"
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})
LINUXMINT_CODENAME=$(lsb_release -cs)
UBUNTU_CODENAME=$(cat /etc/upstream-release/lsb-release | grep DISTRIB_CODENAME= | cut -f2 -d "=")
BACKUP_FILE="assets/backups/home.tar.gz.gpg"

show_message() {
    clear
    printf "${LightColor}$1${NC}\n\n"
}

user_do() {
    if command -v zsh >/dev/null 2>&1; then
        su - ${REGULAR_USER_NAME} -c "/bin/zsh --login -c '$1'"
    else
        su - ${REGULAR_USER_NAME} -c "/bin/bash -c '$1'"
    fi
}

# Fix clock time for windows dualboot
timedatectl set-local-rtc 1

# Check if backup file exists
if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Erro: O arquivo de backup não foi encontrado em '$BACKUP_FILE'. Saindo..."
    exit 1
fi

# Loop até conseguir descriptografar com sucesso
while true; do
  read -s -p "GPG Password: " password
  echo

  show_message "Tentando descriptografar o backup..."
  if echo "$password" | gpg --batch --yes --passphrase-fd 0 --pinentry-mode loopback --decrypt "$BACKUP_FILE" > /tmp/home.tar.gz 2>/dev/null; then
    echo "Descriptografia bem-sucedida!"
    break
  else
    echo "Senha incorreta ou erro ao descriptografar. Tente novamente."
  fi
done

# Extrai e restaura
tar -zxvf /tmp/home.tar.gz -C /home/$REGULAR_USER_NAME/
chown -R $REGULAR_USER_NAME:$REGULAR_USER_NAME /home/$REGULAR_USER_NAME/

# Set mirrors
show_message "Atualizando mirrors"
mirrors="deb https://mint-packages.c3sl.ufpr.br wilma main upstream import backport
deb http://mirror.unesp.br/ubuntu noble main restricted universe multiverse
deb http://mirror.unesp.br/ubuntu noble-updates main restricted universe multiverse
deb http://mirror.unesp.br/ubuntu noble-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse"
echo "$mirrors" > /etc/apt/sources.list.d/official-package-repositories.list

# Disable ESM Ubuntu Pro
rm /etc/apt/apt.conf.d/20apt-esm-hook.conf

# Nvidia Container Toolkit repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Update
show_message "Atualizando repositórios"
apt-get update

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
user_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${REGULAR_UID}/bus' dconf load / < /home/$REGULAR_USER_NAME/.dconf/dconf"

# Update tldr
user_do "tldr --update"

# Upgrade
show_message "Atualizando pacotes"
apt-get upgrade -y

# 32bits packages
show_message "Habilitando pacotes de 32 bits"
dpkg --add-architecture i386

# Install apt-get packages
show_message "Instalando pacotes"
apt-get install -y \
  build-essential \
  git \
  curl \
  wget \
  gpg \
  ca-certificates \
  gnupg \
  lsb-release \
  debconf-utils \
  apt-transport-https \
  python3 \
  python3-gpg \
  python3-pip \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libncurses5-dev \
  libgmp-dev \
  libmysqlclient-dev \
  libyaml-dev \
  libgtk-3-dev \
  liblzma-dev \
  zsh \
  tmux \
  vim \
  neovim \
  gedit \
  fonts-firacode \
  fonts-powerline \
  gparted \
  sox \
  ffmpeg \
  htop \
  neofetch \
  pv \
  ncdu \
  tree \
  whois \
  tlp \
  pavucontrol \
  acpi-call-dkms \
  dkms \
  gnome-system-tools \
  hardinfo \
  p7zip-full \
  virtualbox \
  virtualbox-qt \
  virtualbox-guest-additions-iso \
  unrar \
  rar \
  qpdf \
  exiftool \
  fdupes \
  nmap \
  traceroute \
  jq \
  python3-setuptools \
  mint-meta-codecs \
  software-properties-common \
  libxcb-cursor0 \
  plymouth \
  wine \
  jstest-gtk \
  f3 \
  nvidia-container-toolkit \
  wireguard \
  kdeconnect \
  iperf3 \
  rclone \
  smartmontools \
  iotop \
  dstat \
  mkvtoolnix-gui \
  mame-tools \
  sysstat \
  ovmf \
  ovmf-ia32

# Instalando virtualbox-guest-x11
show_message "Instalando virtualbox-guest-x11"
yes Y | apt-get install -y virtualbox-guest-x11

# Set virtualbox dark theme
show_message "Copiando arquivo de tema para o Virtualbox"
cp ./assets/programs-settings/virtualbox.desktop /usr/share/applications/virtualbox.desktop

# Add user to vbox group
usermod -aG vboxusers $REGULAR_USER_NAME

# Install flatpak packages
show_message "Instalando pacotes flatpak"
flatpak install -y --noninteractive flathub \
  com.google.Chrome \
  com.brave.Browser \
  com.visualstudio.code \
  com.github.calo001.fondo \
  com.github.tchx84.Flatseal \
  org.openshot.OpenShot \
  com.bitwarden.desktop \
  com.discordapp.Discord \
  com.spotify.Client \
  org.librehunt.Organizer \
  com.stremio.Stremio \
  com.anydesk.Anydesk \
  net.xmind.XMind \
  com.obsproject.Studio \
  com.microsoft.Edge \
  rest.insomnia.Insomnia \
  com.getpostman.Postman \
  io.beekeeperstudio.Studio \
  com.sublimetext.three \
  org.gimp.GIMP \
  org.inkscape.Inkscape \
  org.blender.Blender \
  org.mozilla.Thunderbird \
  org.videolan.VLC \
  org.filezillaproject.Filezilla \
  com.valvesoftware.Steam \
  org.audacityteam.Audacity \
  org.gnome.Cheese \
  org.raspberrypi.rpi-imager \
  org.remmina.Remmina \
  com.dropbox.Client \
  org.wireshark.Wireshark \
  md.obsidian.Obsidian \
  org.qbittorrent.qBittorrent \
  org.telegram.desktop \
  com.sweethome3d.Sweethome3d \
  fr.handbrake.ghb \
  org.kde.kdenlive \
  com.calibre_ebook.calibre \
  org.libretro.RetroArch \
  net.pcsx2.PCSX2 \
  org.flameshot.Flameshot \
  org.kiwix.desktop

# Update flatpak
show_message "Atualizando pacotes flatpak"
flatpak update -y

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

# ---- Programming things
# Instalar docker
show_message "Instalando Docker"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
docker run hello-world
groupadd docker
usermod -aG docker $REGULAR_USER_NAME

# Criar uma rede Docker para comunicação entre os contêineres
docker network create web-network

# Configurar um contêiner com Apache (não executar)
show_message "Instalando Apache"
docker create \
  --name apache \
  --network web-network \
  -v /var/www/html:/var/www/html \
  -p 80:80 \
  httpd:latest

# Configurar um contêiner com Nginx
show_message "Instalando Nginx"
docker create \
  --name nginx \
  --network web-network \
  -v /var/www/html:/usr/share/nginx/html \
  -p 8080:80 \
  nginx:latest

# Configurar um contêiner com PHP
show_message "Instalando PHP"
docker create \
  --name php \
  --network web-network \
  -v /var/www/html:/var/www/html \
  php:8.2-fpm

# Install composer
show_message "Instalando PHP composer"
docker pull composer:latest

# Configurar um contêiner com MySQL
show_message "Instalando MySQL"
docker create \
  --name mysql \
  --network web-network \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=default_db \
  -e MYSQL_USER=user \
  -e MYSQL_PASSWORD=secret \
  -p 3306:3306 \
  mysql:8.0

# Install ollama
show_message "Instalando Ollama"
docker pull ollama/ollama

# Define zsh como shell padrão
show_message "Definir zsh como shell padrão"
chsh -s $(which zsh) $REGULAR_USER_NAME

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
