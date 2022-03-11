#!/bin/bash

set -e

# Check Necesarios

# Si no eres root te saca 

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
echo "Utiliisateur : administrador"  >> /root/id_ptero.txt
echo "Mot de passe :" >> /root/id_ptero.txt
echo ${bddpass} >> /root/id_ptero.txt
echo "Identifiant pterodactyl"  >> /root/id_ptero.txt
echo "Utilisateur : administrador"  >> /root/id_ptero.txt
echo "Password"  >> /root/id_ptero.txt
echo ${userpass}  >> /root/id_ptero.txt
rm -rf /etc/systemd/system/pteroq.service
rm -rf /etc/systemd/system/wings.service
sleep 3

# Insertar dominio

read -p 'Escriba el dominio' domaine
echo "Tu dominio es: $domaine !"

sleep 1

#
read -p 'Es utilizando un nombre para el dominio ejemplo (panel.ejemplo.com) ATENCION 5.55.55.55 / localhost NO ES UN DOMINIO)?  (y/n) ' -n 1 dom
sleep 1 
echo "Selecionaste $dom"
sleep 1 




 # INSTALACION GENERAL

# Certificado HTTPS
apt install -y software-properties-common dirmngr ca-certificates apt-transport-https apt-transport-https ca-certificates curl gnupg2 software-properties-common zip unzip tar make gcc g++ python python-dev curl gnupg sudo 
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
curl -sL https://deb.nodesource.com/setup_12.x | bash -
apt update

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
sleep 3
apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg


echo "\n*Añaniendo Base de datos y instalando dependecnias"
sleep 3
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:chris-lea/redis-server
curl -sS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | sudo bash
sleep 3

apt update

apt install -y docker.io nodejs mariadb-common mariadb-server mariadb-client php7.3 php7.3-cli php7.3-gd php7.3-mysql php7.3-pdo php7.3-mbstring php7.3-tokenizer php7.3-bcmath php7.3-xml php7.3-fpm php7.3-curl php7.3-zip mariadb-server apache2 libapache2-mod-php7.3 redis-server certbot curl

systemctl start redis-server
systemctl enable redis-server
systemctl start mariadb
systemctl enable mariadb
systemctl enable docker
systemctl start docker

clear
echo "\n*ACTUALIZANDO "
sleep 3

mysql -u root -e "DROP USER administrador;"
mysql -u root -e "DROP DATABASE ptero;"
mysql -u root -e "CREATE USER administrador IDENTIFIED BY '"${bddpass}"';"
mysql -u root -e "CREATE DATABASE ptero;"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO administrador WITH GRANT OPTION;"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.18/panel.tar.gz
tar --strip-components=1 -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'c31c1e292ad7be5f49291169c0ac8f683499edddcfd4e42232982d0fd193004208a58ff6f353fde0012d35fdd72bc394') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --version=1.10.16

php composer.phar install --no-dev --optimize-autoloader
echo "50%"
sleep 3
php artisan key:generate --force
if [ $dom = "y" ]
then

php artisan p:environment:setup --author ramiro@linkcubee.gp --url https://$domaine --timezone America/Buenos_Aires --cache file --session database --queue database --disable-settings-ui
else
php artisan p:environment:setup --author ramiro@linkcubee.gp --url http://$domaine --timezone America/Buenos_Aires --cache file --session database --queue database --disable-settings-ui
fi

clear
echo =================================
echo =================================
echo "PARA ENTRAR EL USUARIO ES:"
echo "USUARIO : administrador"
echo "Contraseña :"
echo ${bddpass}
echo "BDD : ptero"
echo =================================
echo =================================

echo -e -n "\n* ¿Seguir? y/n: "
read -r confirmar

if [[ "$confirmar" =~ [Nn] ]]; then
  exit
      
fi

php artisan p:environment:database --host 127.0.0.1 --port 3306 --database ptero --username administrador --password ${bddpass}
php artisan migrate --seed --force

echo "Creando usuario de pterodactyl"
sleep 4
php artisan p:user:make --admin 1 --email mail@exemple.com --username administrador --name-first exemple --name-last name --password ${userpass}
chown -R www-data:www-data * 

echo "# Activando ficheros de trabajo" >> /etc/systemd/system/pteroq.service
echo "# ----------------------------------" >> /etc/systemd/system/pteroq.service
echo "" >> /etc/systemd/system/pteroq.service
echo "[Unit]" >> /etc/systemd/system/pteroq.service
echo "Descripcion=Trabajados de la cola del pterodáctilo" >> /etc/systemd/system/pteroq.service
echo "After=redis-server.service" >> /etc/systemd/system/pteroq.service
echo "" >> /etc/systemd/system/pteroq.service
echo "[Service]" >> /etc/systemd/system/pteroq.service
echo "#  En algunos sistemas el usuario y el grupo pueden ser diferentes." >> /etc/systemd/system/pteroq.service
echo "User=www-data" >> /etc/systemd/system/pteroq.service
echo "Group=www-data" >> /etc/systemd/system/pteroq.service
echo "Restart=always" >> /etc/systemd/system/pteroq.service
echo "ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3" >> /etc/systemd/system/pteroq.service
echo "" >> /etc/systemd/system/pteroq.service
echo "[Instalando]" >> /etc/systemd/system/pteroq.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/pteroq.service

sudo systemctl enable --now redis-server
sudo systemctl enable --now pteroq.service

if [ $dom = "y" ]
then


        echo "=============================="
        echo "Haciendo instalacion de certificado https"
        echo "=============================="

        sleep 2
        apt update
        apt install -y certbot
        echo "Instalando Certbot y activando credenciales"
        service apache2 stop
        service nginx stop 
        certbot certonly --standalone --agree-tos --no-eff-email --register-unsafely-without-email -d $domaine
        echo "=============================="
        echo "Certificado ssl creado"
        echo "=============================="
        rm -rf /etc/apache2/sites-enabled/pterodactyl.conf


echo "<VirtualHost *:80>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  ServerName" $domaine >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  RewriteEngine On" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  RewriteCond %{HTTPS} !=on" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L] " >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "</VirtualHost>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "<VirtualHost *:443>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  ServerName" $domaine >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  DocumentRoot "/var/www/pterodactyl/public"" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  AllowEncodedSlashes On" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  php_value upload_max_filesize 100M" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  php_value post_max_size 100M" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  <Directory "/var/www/pterodactyl/public">" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "    AllowOverride all" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  </Directory>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  SSLEngine on" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  SSLCertificateFile /etc/letsencrypt/live/"$domaine"/fullchain.pem" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  SSLCertificateKeyFile /etc/letsencrypt/live/"$domaine"/privkey.pem" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "</VirtualHost> " >> /etc/apache2/sites-enabled/pterodactyl.conf

chmod -R 755 /var/www/pterodactyl/public && chown -R www-data:www-data /var/www/pterodactyl/public
a2enmod rewrite
a2enmod ssl
service apache2 restart

else
		echo "=============================="

        echo "No tienes nombre de dominio certbot no se instalara"
		echo "=============================="

		sleep 5
				rm -rf /etc/apache2/sites-enabled/pterodactyl.conf

echo "<VirtualHost *:80>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  ServerName" $domaine >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  DocumentRoot "/var/www/pterodactyl/public"" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  AllowEncodedSlashes On" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  php_value upload_max_filesize 100M" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  php_value post_max_size 100M" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  <Directory "/var/www/pterodactyl/public">" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "    AllowOverride all" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "  </Directory>" >> /etc/apache2/sites-enabled/pterodactyl.conf
echo "</VirtualHost>" >> /etc/apache2/sites-enabled/pterodactyl.conf
a2enmod rewrite
a2enmod ssl
service apache2 restart

fi

echo "=============================="
echo "instalando packetes de idioma"
echo "=============================="
sleep 3
echo instalando 
sleep 1

cd /var/www/pterodactyl/public/
mkdir pma
cd pma
wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.zip
unzip phpMyAdmin-5.0.2-all-languages.zip
mv phpMyAdmin-5.0.2-all-languages/* /var/www/pterodactyl/public/pma
rm -rf phpM*


echo "====="

echo "====="

slepe 2
echo "====="
echo "Instalando daemon"
echo "====="
sleep 2

mkdir -p /srv/daemon /srv/daemon-data
cd /srv/daemon
curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.13/daemon.tar.gz | tar --strip-components=1 -xzv

npm install --only=production --no-audit --unsafe-perm

echo "[Unit]" >> /etc/systemd/system/wings.service
echo "Description=Pterodactyl Wings Daemon" >> /etc/systemd/system/wings.service
echo "After=docker.service" >> /etc/systemd/system/wings.service
echo "" >> /etc/systemd/system/wings.service
echo "[Service]" >> /etc/systemd/system/wings.service
echo "User=root" >> /etc/systemd/system/wings.service
echo "#Group=some_group" >> /etc/systemd/system/wings.service
echo "WorkingDirectory=/srv/daemon" >> /etc/systemd/system/wings.service
echo "LimitNOFILE=4096" >> /etc/systemd/system/wings.service
echo "PIDFile=/var/run/wings/daemon.pid" >> /etc/systemd/system/wings.service
echo "ExecStart=/usr/bin/node /srv/daemon/src/index.js" >> /etc/systemd/system/wings.service
echo "Restart=on-failure" >> /etc/systemd/system/wings.service
echo "StartLimitInterval=600" >> /etc/systemd/system/wings.service
echo "" >> /etc/systemd/system/wings.service
echo "[Install]" >> /etc/systemd/system/wings.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/wings.service

echo "Identifiant pterodactyl"
echo "Utilisateur : administrador"  
echo "Password"  
echo ${userpass}  
read -p "Pegue aqui su Token creado desde el panel " cmd
${cmd} 
systemctl enable --now wings
echo "=============================="
echo "=============================="
echo "Fin del script"

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
