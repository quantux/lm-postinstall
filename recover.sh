#!/bin/bash

# Checks for root privileges
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

# Terminal colors
LightColor='\033[1;32m'
NC='\033[0m'

# Get current regular user (not sudo user)
REGULAR_USER_NAME=$(who am i | awk '{print $1}')
REGULAR_UID=$(id -u ${REGULAR_USER_NAME})

# Distro codenames
LINUXMINT_CODENAME=$(lsb_release -cs)
UBUNTU_CODENAME=$(cat /etc/upstream-release/lsb-release | grep DISTRIB_CODENAME= | cut -f2 -d "=")

# Base project dir
BASE_DIR=$(pwd)

show_message() {
    clear
    printf "${LightColor}$1${NC}\n\n"
}

user_bash_do() {
    # sudo -u ${REGULAR_USER_NAME} /bin/bash -c "$1"
    su - ${REGULAR_USER_NAME} -c "$1"
}

user_zsh_do() {
    # sudo -u ${REGULAR_USER_NAME} /bin/zsh -c "source ~/.zshrc; $1"
    su - ${REGULAR_USER_NAME} -c "/bin/zsh --login -c '$1'"
}

# Fix clock time for windows dualboot
timedatectl set-local-rtc 1

# asks for gpg password confirmation
while true; do
  read -s -p "GPG Password: " password
  echo
  read -s -p "Password confirmation: " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done

# Set mirrors
show_message "Atualizando mirrors"
mirrors="deb https://mirror.ufscar.br/mint-archive $LINUXMINT_CODENAME main upstream import backport \n\n\
deb http://sft.if.usp.br/ubuntu $UBUNTU_CODENAME main restricted universe multiverse\n\
deb http://sft.if.usp.br/ubuntu $UBUNTU_CODENAME-updates main restricted universe multiverse\n\
deb http://sft.if.usp.br/ubuntu $UBUNTU_CODENAME-backports main restricted universe multiverse\n\n\
deb http://security.ubuntu.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse"
echo -e $mirrors > /etc/apt/sources.list.d/official-package-repositories.list

# Update
show_message "Atualizando repositórios"
apt update

# Instalando libdvd-pkg (único que pede confirmação)
# show_message "Instalando libdvd-pkg"
# apt -y install libdvd-pkg
# dpkg-reconfigure libdvd-pkg

# Instalando libdvd-pkg
# show_message "Instalando libdvd-pkg"
export DEBIAN_FRONTEND=noninteractive
apt -y install libdvd-pkg
dpkg-reconfigure -f noninteractive libdvd-pkg

# Install ttf-mscorefonts-installer
show_message "Instalando ttf-mscorefonts-installer"
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula	boolean	true" | debconf-set-selections
echo "ttf-mscorefonts-installer msttcorefonts/present-mscorefonts-eula note" | debconf-set-selections
apt install -y ttf-mscorefonts-installer

# Recover backup files
show_message "Recuperando arquivos de backup"
echo $password2 | gpg --batch --yes --passphrase-fd 0 --decrypt assets/backups/home.tar.gz.gpg > /tmp/home.tar.gz
tar -zxvf /tmp/home.tar.gz -C /tmp
rsync -aAXv /tmp/home/ /home/$REGULAR_USER_NAME/
chown -R $REGULAR_USER_NAME:$REGULAR_USER_NAME /home/$REGULAR_USER_NAME/

# Recover dconf
echo $password2 | gpg --batch --yes --passphrase-fd 0 --decrypt assets/cinnamon-settings/dconf/dconf.gpg > /tmp/dconf

# Update tldr
user_bash_do "tldr --update"

# Upgrade
show_message "Atualizando pacotes"
apt upgrade -y

# 32bits packages
show_message "Habilitando pacotes de 32 bits"
dpkg --add-architecture i386

# Install apt packages
show_message "Instalando pacotes"
apt install -y \
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
  gedit \
  fonts-firacode \
  fonts-powerline \
  gparted \
  sox \
  ffmpeg \
  htop \
  neofetch \
  screenfetch \
  pv \
  ncdu \
  tree \
  speedtest-cli \
  whois \
  tlp \
  pavucontrol \
  acpi-call-dkms \
  dkms \
  gnome-system-tools \
  gnome-boxes \
  hardinfo \
  p7zip-full \
  unrar \
  rar \
  qpdf \
  exiftool \
  fdupes \
  nmap \
  traceroute \
  jq \
  python3-setuptools \
  gnome-system-tools \
  ubuntu-restricted-extras \
  software-properties-common \
  libxcb-cursor0 \
  plymouth \
  wine \
  jstest-gtk \
  scrcpy \
  libncurses5-dev

# Instalando virtualbox-guest-x11
show_message "Instalando virtualbox-guest-x11"
yes Y | apt install -y virtualbox-guest-x11

# Add user to vbox group
usermod -aG vboxusers $REGULAR_USER_NAME

# Instalando wireshark
show_message "Instalando wireshark"
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y wireshark

# Install pylint
show_message "Instalando pylint"
pip3 install pylint

# Install flatpak packages
show_message "Instalando pacotes flatpak"
flatpak install -y --noninteractive flathub \
  com.github.calo001.fondo \
  com.github.tchx84.Flatseal \
  org.openshot.OpenShot \
  com.bitwarden.desktop \
  com.discordapp.Discord \
  com.spotify.Client \
  org.librehunt.Organizer \
  com.stremio.Stremio \
  net.xmind.XMind \
  com.obsproject.Studio \
  com.visualstudio.code \
  com.microsoft.Edge \
  rest.insomnia.Insomnia \
  com.getpostman.Postman \
  io.beekeeperstudio.Studio \
  com.google.AndroidStudio \
  com.anydesk.Anydesk \
  io.neovim.nvim \
  com.sublimetext.three \
  org.gimp.GIMP \
  org.inkscape.Inkscape \
  org.blender.Blender \
  org.mozilla.firefox \
  org.mozilla.Thunderbird \
  org.videolan.VLC \
  org.filezillaproject.Filezilla \
  com.valvesoftware.Steam \
  org.audacityteam.Audacity \
  org.gnome.Cheese \
  org.raspberrypi.rpi-imager \
  org.remmina.Remmina \
  com.dropbox.Client

# Update flatpak
show_message "Atualizando pacotes flatpak"
flatpak update -y

# Install Chrome
show_message "Instalando Google Chrome"
wget "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -O /tmp/google-chrome.deb
dpkg -i /tmp/google-chrome.deb
apt install -fy

# Install - Adapta Nokto Fonts
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

# Install Sweet Theme
show_message "Instalando Sweet Theme"
tar -xf ./assets/themes/Sweet-mars-v40.tar.xz -C /usr/share/themes

# Install Sweet Theme
show_message "Instalando Flat Remix theme"
tar -xf ./assets/themes/Flat-Remix-GTK-Blue-Darkest-Solid-NoBorder.tar.xz -C /usr/share/themes

# La-Capitaine Icons
show_message "Instalando ícones La-Capitaine"
tar -zxvf ./assets/icons/la-capitaine.tar.gz -C /usr/share/icons/

# WPS Office Fonts
show_message "Instalando fontes para o WPS Office"
git clone https://github.com/udoyen/wps-fonts.git /tmp/wps-fonts
mv /tmp/wps-fonts/wps /usr/share/fonts/

# Set virtualbox dark theme
show_message "Copiando arquivo de tema para o Virtualbox"
cp ./assets/programs-settings/virtualbox.desktop /usr/share/applications/virtualbox.desktop

# Install Teamviewer
show_message "Instalando TeamViewer"
wget "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" -O /tmp/teamviewer.deb
dpkg -i /tmp/teamviewer.deb
apt install -fy

# Install oh-my-zsh
# show_message "Instalando oh-my-zsh"
# user_bash_do "sh ./assets/oh-my-zsh/oh-my-zsh-install.sh --unattended"
# chsh -s $(which zsh) $(whoami)

# Install oh-my-posh
# show_message "Instalando oh-my-posh"
# wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 -O /usr/local/bin/oh-my-posh
# chmod +x /usr/local/bin/oh-my-posh

# Load dconf file
show_message "Carregando configurações do dconf"
user_bash_do "DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${REGULAR_UID}/bus' dconf load / < /tmp/dconf"

# Set Transmission as default magnet link app
xdg-mime default transmission-gtk.desktop x-scheme-handler/magnet

# Install grub2-themes
# show_message "Instalando grub themes"
# git clone https://github.com/vinceliuice/grub2-themes assets/grub-themes/grub2-themes
# ./assets/grub2-themes/install.sh -b -t vimix

# Install minimal-grub-theme
# git clone https://github.com/tomdewildt/minimal-grub-theme assets/grub-themes/minimal-grub-theme
# cd assets/grub-themes/minimal-grub-theme
# make install
# cd $BASE_DIR

# Install grub-customizer
show_message "Instalando grub-customizer"
add-apt-repository ppa:danielrichter2007/grub-customizer -y
apt update
apt install -y grub-customizer

# Install snapd
# show_message "Instalando snapd"
# rm /etc/apt/preferences.d/nosnap.pref
# apt update
# apt install -y snapd

# Allow games run in fullscreen mode
echo "SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0" >> /etc/environment

# ---- Programming things
# Instalar docker
show_message "Instalando Docker"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
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

# Install Homebrew and Github CLI
show_message "Instalando Homebrew e Github CLI"
user_bash_do "sh ./assets/homebrew/install.sh --unattended"
user_bash_do "brew install gh"

# Define zsh como shell padrão
show_message "Definir zsh como shell padrão"
user_bash_do "chsh -s $(which zsh)"

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
