#!/bin/bash

CONFIG="https://raw.githubusercontent.com/mato176/prueba_pt/main/config/"
NGINX_NONSSL="ngnix_nonssl.conf"
NGINX_SSL="ngnix_ssl.conf"

greenMessage() {
	echo -e "\\033[32;1m${@}\033[0m"
}

update(){
	greenMessage "** Actualizando"
	apt update -y
}
fliglet(){
  sudo apt-get install figlet
  figlet LinkCubee Script
}


domaine(){
read -p 'Escriba el dominio: ' domaine
echo "Tu dominio es: $domaine"
}

 # INSTALACION GENERAL
install_dependency(){
# Certificado HTTPS
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
#descarga de mariadb
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
echo "\n*INSTALANDO REPOSITORIOS"
apt -y install php8.0 php8.0-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip,docker.io,certbot} mariadb-server nginx tar unzip git redis-server
apt update
}

Open_Port(){
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
}


install_composer(){
echo "\n*Instalando compuser"
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
}

dl_files(){
	greenMessage "** Downloading Some Files.."

	mkdir -p /var/www/pterodactyl
	cd /var/www/pterodactyl
	curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.14/panel.tar.gz
	tar --strip-components=1 -xzvf panel.tar.gz
	chmod -R 755 storage/* bootstrap/cache/
}

setup_mysql(){
	greenMessage "** Mysql Setup Starting.."

	mysql_secure_installation

	echo -n "* Enter MySQL Root Password: "
	read RPASS

	until mysql -u root -p${RPASS}  -e ";" ; do
       read -s -p "Incorrect MySQL root password, TRY AGAIN: " RPASS
	done

	mysql -u root -p{RPASS} -e "USE mysql;"

	echo -n "* Set MySQL User Password: "
  	read SPASS

  	greenMessage "Created MySQL USER.."
	mysql -u root -p{RPASS} -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${SPASS}';"

	greenMessage "Created Database.."
	mysql -u root -p{RPASS} -e "CREATE DATABASE panel;"

	greenMessage "Granted Access to MySQL User.."
	mysql -u root -p{RPASS} -e "GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"

	greenMessage "Flushesd PRIVILEGES.."
	mysql -u root -p{RPASS} -e "FLUSH PRIVILEGES;"

	echo "*****************************************"
	greenMessage "Database User: pterodactyl"
	greenMessage "Database Pass: ${SPASS}"
	greenMessage "Database Name: panel"
	echo "pterodactyl:${SPASS}:panel" >> mysql_credentials.txt
	echo "*****************************************"
}

installation(){
	greenMessage "** Main Installation.."
	cp .env.example .env
	composer install --no-dev --optimize-autoloader

	# Only run the command below if you are installing this Panel for
	# the first time and do not have any Pterodactyl Panel data in the database.
	php artisan key:generate --force
}

configure(){
	greenMessage "** Configurations.."

	php artisan p:environment:setup

	php artisan p:environment:database

	php artisan p:environment:mail
}

database_setup(){
	greenMessage "** Setup Database.."
	php artisan migrate --seed
}

adduser() {
	greenMessage "** Adding User.."
	php artisan p:user:make
}

setPermission(){
	greenMessage "** File Permission Setup.."
	chown -R www-data:www-data * 
}

crontab_setup(){
	greenMessage "** Cronjob Setup.."
	CRON="* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1"
	crontab -l | { cat; echo "${CRON}"; } | crontab -
}

create_pteroq(){
	greenMessage "** Pteroq Config File Downloading.."

	curl -o /etc/systemd/system/pteroq.service ${CONFIG}/pteroq.service

	#sudo systemctl enable --now redis-server
	sudo systemctl enable --now pteroq.service
}

web_ngnix(){
	greenMessage "** Ngnix Config Downloading & Setup"

	rm -rf /etc/nginx/sites-enabled/default
	curl -o /etc/nginx/sites-available/pterodactyl.conf ${CONFIG}/${NGINX_NONSSL}

	echo -n "* Enter Panel IP or Hostname: "
  	read FQDN
  	
	sed -i -e "s/<domain>/${FQDN}/g" /etc/nginx/sites-available/pterodactyl.conf

	sudo ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
	systemctl restart nginx
}

install_complete(){
	greenMessage "** Pterodactyl Panel Installed Successfull!"
}

