#!/bin/bash

sudo su

#* --- CONFIGURAR DISCO /var/lib/elasticsearch --- *#


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
vgcreate vg_elasticsearch /dev/sdc1 # crear Volume Group con combre vg_elasticsearch en el volumen físico /dev/sdc1
lvcreate -n lv_elasticsearch_data -l 100%FREE vg_elasticsearch # crear el volumen lógico sobre el vg vg_elasticsearch, con nombre mariadb_data y ocupando todo el espacio del vg


mkfs.ext4 /dev/vg_elasticsearch/lv_elasticsearch_data # crear el sistema de ficheros con formato EXT4
mkdir /var/lib/elasticsearch
mount /dev/vg_elasticsearch/lv_elasticsearch_data /var/lib/elasticsearch # montar la partición en el /var/lib/elasticsearch
echo "/dev/mapper/vg_elasticsearch-lv_elasticsearch_data   /var/lib/elasticsearch  ext4    defaults    0 0" >> /etc/fstab # hacer el montaje permanente

rm -R /var/lib/elasticsearch/* 

useradd elasticsearch
chown -R elasticsearch: /var/lib/elasticsearch



#****** REPOSITORIOS Y CLAVES ******#

#*___ elasticsearch
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

apt-get install apt-transport-https

echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list



#****** ISTALACIONES ******#

apt update

#*___ nginx (para kibana)
apt install -y nginx

#*___ Java para el stack elk
apt install -y default-jre



#*___ Logstash
apt install -y logstash

# _ config
cp /vagrant/config/elk/conf.d/* /etc/logstash/conf.d
systemctl start logstash
systemctl enable logstash


#*___ elasticsearch
apt install -y elasticsearch

# _ config
sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/' /etc/elasticsearch/elasticsearch.yml

systemctl start elasticsearch
systemctl enable elasticsearch


#*___ Kibana
apt install -y kibana

# _ config
cat /vagrant/config/elk/nginx_elk > /etc/nginx/sites-available/default

echo "kibanaadmin:$(openssl passwd -apr1 -in /vagrant/config/elk/.kibana)" | sudo tee -a /etc/nginx/htpasswd.users
systemctl start kibana
systemctl enable kibana
systemctl reload nginx

systemctl daemon-reload
