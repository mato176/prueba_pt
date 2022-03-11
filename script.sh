#!/bin/bash

set -e

# Check Necesarios

# Si no eres root te saca 

sudo apt update

if [[ $EUID -ne 0 ]]; then
  echo "* Ponte root" 1>&2
  exit 1
fi

# Check de curl
if ! [ -x "$(command -v curl)" ]; then
  echo "* curl es necesario para que funcione el script instalalo."
  echo "* Instalar con npm (ubuntu/debian) o yum/dnf (CentOS)"
  exit 1
fi

# Baner
sudo apt-get install figlet

figlet LinkCubee Script

# Comenzar con la instalacion

  echo -e -n "\n* ¿Iniciar instalacion? (y/N): "
  read -r CONFIRM
  if [[ "$CONFIRM" =~ [Yy] ]]; then
    perform_install
  else
    print_error "Instalacion cancelada"
    exit 1
  fi

# INSTALACION GENERAL
perform_install() {
echo -ne '#####                     (33%)\r'
sleep 2
sudo apt install firewalld -y
sudo firewall-cmd --add-service=http --permanent
echo -ne '#############             (66%)\r'
sleep 2
sudo firewall-cmd --add-service=https --permanent
sudo firewall-cmd --reload
echo -ne '#######################   (100%)\r'
echo -ne '\n'


sleep 3

echo "*INSTALANDO REPOSITORIOS"
sleep 3
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg


echo "*Añaniendo Base de datos"
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
sleep 3

echo "*ACTUALIZANDO "
sleep 3
apt update

echo "*Repositorios universales "
sleep 3
apt-add-repository universe


echo "*Instalacion de php "
sleep 3
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server


echo "*Composer "
sleep 3
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

echo "*Crear carpeta "
sleep 3
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
}
