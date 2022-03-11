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

clear 
# Baner
sudo apt-get install figlet

figlet LinkCubee Script

# Comenzar con la instalacion


  echo -e -n "\n* ¿Quieres comenzar? y/n: "
  read -r confirmar

  if [[ "$confirmar" =~ [Nn] ]]; then
    exit
      
  fi


 # INSTALACION GENERAL

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

clear
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

echo "*EXTRAYENDO TODO LOS ARCHIVOS"
sleep 3
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/ 

echo "*CONFIGURANDO MYSQL"
sleep 3
mysql -u root -p

echo "*Creando usuario de base de dato"
sleep 5
echo "*¿Contrasena para base de datos?"
read contrasena
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$contrasena';

CREATE DATABASE panel;
echo "*base de datos creada"
