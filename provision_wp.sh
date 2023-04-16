#!/bin/bash
 
sudo su


#* --- CONFIGURAR DISCO /var/lib/mysql --- *#


# cambiar tabla de particiones a GPT (g), crear una nueva partición (n, 1) con todo el disco (\n,\n) del tipo Linux LVM (t, 30)
fdisk /dev/sdc << EOF_sdc
g
n
1


t
30
w
EOF_sdc


# Utilizar LVM para crear un volumen lógico a partir de ese disco
pvcreate /dev/sdc1 # crear volumen físico
vgcreate vg_mariadb /dev/sdc1 # crear Volume Group con combre vg_mariadb en el volumen físico /dev/sdc1
lvcreate -n lv_mariadb_data -l 100%FREE vg_mariadb # crear el volumen lógico sobre el vg vg_mariadb, con nombre mariadb_data y ocupando todo el espacio del vg


mkfs.ext4 /dev/vg_mariadb/lv_mariadb_data # crear el sistema de ficheros con formato EXT4
mkdir /var/lib/mysql
mount /dev/vg_mariadb/lv_mariadb_data /var/lib/mysql # montar la partición en el /var/lib/mysql
echo "/dev/mapper/vg_mariadb-lv_mariadb_data   /var/lib/mysql  ext4    defaults    0 0" >> /etc/fstab # hacer el montaje permanente





#* --- INSTALAR NGINX --- *#


# instalar nginx, mariaDB y php

apt update
apt install -y nginx mariadb-server mariadb-common php-fpm php-mysql expect php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip



#* --- CONFIGURAR NGINX --- *#

cd /etc/nginx/sites-available

# crear el fichero de configuración
cat << EOF > wordpress
# Managed by installation script - Do not change 

server {
    listen 80;
    root /var/www/wordpress;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name localhost;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF

# crear el enlace simbólico en sites-enabled
ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress

rm /etc/nginx/sites-enabled/default

# cargar los cambios
systemctl reload nginx


#* --- CONFIGURACIONES DE SEGURIDAD DE MARIADB --- *#

mysql --user=root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED BY '123';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost' IDENTIFIED BY 'keepcoding';
FLUSH PRIVILEGES;
_EOF_


#* --- INSTALAR WORDPRESS --- *#

cd /var/www/

# descargar wordpres desde https://wordpress.org/latest.tar.gz
wget https://wordpress.org/latest.tar.gz

# descomprimir fichero wordpress
tar xzvf latest.tar.gz

# eliminar fichero latest
rm latest.tar.gz


#* --- CONFIGURAR WORDPRESS --- *#

# cambiar usuario y grupo
chown www-data:www-data /var/www/wordpress/ -R

# configurar la BD de wordpress
cd wordpress
cp wp-config-sample.php wp-config.php

sed -i 's/database_name_here/wordpress/' wp-config.php
sed -i 's/username_here/root/' wp-config.php
sed -i 's/password_here/123/' wp-config.php
sed -i 's/wp_/kc_/' wp-config.php


#* --- INSTALAR FILEBEAT --- *#

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

apt update
apt install -y filebeat

#* --- CONFIGURAR FILEBEAT --- *#

filebeat modules enable system
filebeat modules enable nginx

cp /vagrant/config/wp/filebeat.yml /etc/filebeat/filebeat.yml

systemctl start filebeat
systemctl enable filebeat