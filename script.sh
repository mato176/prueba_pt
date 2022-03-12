#!/bin/bash

# Check Necesarios

#variable
CONFIG="https://raw.githubusercontent.com/mato176/prueba_pt/main/config/"
NGINX_NONSSL="ngnix_nonssl.conf"
NGINX_SSL="ngnix_ssl.conf"

greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

sudo apt update

if [[ $EUID -ne 0 ]]; then
  echo "\n* Ponte root" 1>&2
  exit 1
fi

# Check de curl
if ! [ -x "$(command -v curl)" ]; then
  echo "\n* curl es necesario para que funcione el script instalalo."
  echo "\n* Instalar con npm (ubuntu/debian) o yum/dnf (CentOS)"
  exit 1
fi

clear 
# Baner
sudo apt-get install figlet

figlet LinkCubee Script


echo -e -n "\n* ¿Comenzar instalacion? y/n: "
read -r confirmar

if [[ "$confirmar" =~ [Nn] ]]; then
  exit
      
fi

# Variables


echo ======== Haciendo Ajustes =============
bddpass=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1)
userpass=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1)
rm -rf /root/id_ptero.txt
rm -rf /var/www/pterodactyl/*
echo "Identifiant SQL" >> /root/id_ptero.txt
echo "Utiliisateur : administrateur"  >> /root/id_ptero.txt
echo "Mot de passe :" >> /root/id_ptero.txt
echo ${bddpass} >> /root/id_ptero.txt
echo "Identifiant pterodactyl"  >> /root/id_ptero.txt
echo "Utilisateur : administrateur"  >> /root/id_ptero.txt
echo "Password"  >> /root/id_ptero.txt
echo ${userpass}  >> /root/id_ptero.txt
rm -rf /etc/systemd/system/pteroq.service
rm -rf /etc/systemd/system/wings.service
sleep 3

# Insertar dominio

read -p 'Escriba el dominio: ' domaine
echo "Tu dominio es: $domaine"

sleep 1

#
read -p '¿Esta utilizando un nombre para el dominio? ejemplo (panel.ejemplo.com) ATENCION 5.55.55.55 / localhost NO ES UN DOMINIO  (y/n) ' -n 1 dom
sleep 1 
echo "Selecionaste $dom"
sleep 1 




 # INSTALACION GENERAL

# Certificado HTTPS
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg

#descarga de mariadb
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash

# Abriendo puertos
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

echo "\n*INSTALANDO REPOSITORIOS"
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip,docker.io,certbot} mariadb-server nginx tar unzip git redis-server

echo "\n*Instalando compuser"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer


apt update

echo "\n*Activando servicios"

systemctl start mariadb
systemctl enable mariadb
systemctl enable docker
systemctl start docker

clear
echo "\n*ACTUALIZANDO "
sleep 3

mysql -u root -e "DROP USER administrateur;"
mysql -u root -e "DROP DATABASE ptero;"
mysql -u root -e "CREATE USER administrateur IDENTIFIED BY '"${bddpass}"';"
mysql -u root -e "CREATE DATABASE ptero;"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO administrateur WITH GRANT OPTION;"

echo "\n*Creando carpeta pterodactyl"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.18/panel.tar.gz
tar --strip-components=1 -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env
php composer.phar install --no-dev --optimize-autoloader
echo "VAMOS EN EL 50%"
sleep 3
php artisan key:generate --force
if [ $dom = "y" ]
then

php artisan p:environment:setup --author mato3143@gmail.com --url https://$domaine --timezone America/Toronto --cache file --session database --queue database --disable-settings-ui
else
php artisan p:environment:setup --author mato3143@gmail.com --url http://$domaine --timezone America/Toronto --cache file --session database --queue database --disable-settings-ui
fi

clear
echo =================================
echo =================================
echo "PARA ENTRAR EL USUARIO ES:"
echo "Usuario : administrateur"
echo "Contraseña :"
echo ${bddpass}
echo "BDD : ptero"
echo "dominio:"http://$domaine
echo =================================
echo =================================
sleep 10
echo -e -n "\n* ¿Seguir? y/n: "
read -r confirmar

if [[ "$confirmar" =~ [Nn] ]]; then
  exit
      
fi

php artisan p:environment:database --host 127.0.0.1 --port 3306 --database ptero --username administrateur --password ${bddpass}
php artisan migrate --seed --force

echo "Creando usuario de pterodactyl"
sleep 4
php artisan p:user:make --admin 1 --email mato3143@gmail.com --username administrateur --name-first ramiro --name-last figueroa --password ${userpass}
chown -R www-data:www-data /var/www/pterodactyl/* 

crontab_setup(){
	greenMessage "** Cronjob Setup.."
	CRON="* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
	crontab -l | { cat; echo "${CRON}"; } | crontab -
}

create_pteroq(){
	greenMessage "** Pteroq configurando y descargando."

	curl -o /etc/systemd/system/pteroq.service ${CONFIG}/pteroq.service

	#sudo systemctl enable --now redis-server
	sudo systemctl enable --now pteroq.service
}

web_ngnix(){
	greenMessage "** Ngnix configurando y descargando"

	rm -rf /etc/nginx/sites-enabled/default
	curl -o /etc/nginx/sites-available/pterodactyl.conf ${CONFIG}/${NGINX_NONSSL}


  	
	sed -i -e "s/<domain>/${domaine}/g" /etc/nginx/sites-available/pterodactyl.conf

	sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
	systemctl restart nginx
}

install_complete(){
	greenMessage "** INSTALACION COMPLETA DE Pterodactyl Panel"
}

update
install_dependency
install_composer
dl_files
setup_mysql
installation
configure
database_setup
adduser
setPermission
crontab_setup
create_pteroq
web_ngnix
install_complete


echo "Sus identidades están en el archivo /root/id_ptero.txt"
if [ $dom = "y" ]
then
echo "Acceda a Pterodactyl aqui https://$domaine/"
echo "Acceda a  PhpMyAdmin aqui https://$domaine/pma"
else
echo "Acceda a Pterodactyl aqui http://$domaine/"
echo "Acceda a PhpMyAdmin aqui http://$domaine/pma"
fi
echo "=============================="
echo "=============================="

sleep 5
