#!/bin/bash

# This script installs TileMill, PostGIS, nginx, and does some basic configuration.
# The set up it creates has basic security: port 20009 can only be accessed through port 80, which has password auth.

# The Postgres database tuning assumes 32 Gb RAM.

# Author: Steve Bennett

echo "127.0.01 `hostname`" | sudo tee -a /etc/hosts

wget https://github.com/downloads/mapbox/tilemill/install-tilemill.tar.gz
tar -xzvf install-tilemill.tar.gz

sudo apt-get install -y policykit-1

#As per https://github.com/gravitystorm/openstreetmap-carto

#sudo bash install-tilemill.sh

#And hence here: http://www.postgis.org/documentation/manual-2.0/postgis_installation.html
#? 
sudo apt-get install -y postgresql libpq-dev postgis

# Install OSM2pgsql

sudo apt-get install -y software-properties-common git unzip
sudo add-apt-repository -y ppa:kakrueger/openstreetmap
sudo apt-get update
sudo apt-get install -y osm2pgsql

#(leave all defaults)

#Install TileMill

sudo add-apt-repository -y ppa:developmentseed/mapbox
sudo apt-get update

sudo apt-get install -y tilemill

# less /etc/tilemill/tilemill.config
# Verify that server: true

sudo start tilemill

# To tunnel to the machine, if needed:
# ssh -CA nectar-maps -L 21009:localhost:20009 -L 21008:localhost:20008
# Then access it at localhost:21009

# Configure Postgres

echo "CREATE ROLE ubuntu WITH LOGIN CREATEDB UNENCRYPTED PASSWORD 'ubuntu'" | sudo -su postgres psql
# Argh - can't crack the right combination here. I give up in the end and just ubuntu a superuser. Just needs
# to be able to modify the 'relation' spatial_ref_sys
echo "GRANT ALL ON DATABASE gis TO ubuntu" | sudo -su postgres psql
echo "GRANT ALL ON SCHEMA public TO ubuntu" | sudo -su postgres psql
echo "GRANT ALL ON ALL TABLES IN SCHEMA public TO ubuntu" | sudo -su postgres psql
#echo "GRANT Superuser, Create role, Create DB, Replication TO ubuntu" | sudo -su postgres psql
echo "ALTER USER ubuntu WITH SUPERUSER" | sudo -su postgres psql

# sudo -su postgres bash -c 'createuser -d -a -P ubuntu'

#(password 'ubuntu') (blank doesn't work well...)

# === Unsecuring TileMill

export IP=`curl http://ifconfig.me`

cat > tilemill.config <<FOF
{
  "files": "/usr/share/mapbox",
  "coreUrl": "$IP:20009",
  "tileUrl": "$IP:20008",
  "listenHost": "0.0.0.0",
  "server": true
}
FOF
sudo cp tilemill.config /etc/tilemill/tilemill.config

# ======== Postgres performance tuning
sudo bash
cat >> /etc/postgresql/9.1/main/postgresql.conf <<FOF
# Steve's settings
shared_buffers = 8GB
autovaccuum = on
effective_cache_size = 8GB
work_mem = 128MB
maintenance_work_mem = 64MB
wal_buffers = 1MB

FOF
exit

# ==== Automatic start 
cat > /tmp/rc.local <<FOF
#!/bin/sh -e
sysctl -w kernel.shmmax=8000000000
service postgresql start
start tilemill
service nginx start
exit 0
FOF

sudo cp /tmp/rc.local /etc/rc.local

# === Securing with nginx
sudo apt-get -y install nginx

cd /etc/nginx
sudo bash <<FOF
printf "maps:$(openssl passwd -crypt 'URPA$WD')\n" >> htpasswd
chown root:www-data htpasswd
chmod 640 htpasswd
FOF

# In the following config, http_host is literally a dollar sign then http_host
# whereas IP is a shell variable that should be substituted at the time the config is written.
cat > /tmp/sites-enabled-default <<FOF

server {
   listen 80;
   server_name localhost;
   # This configuration allows TileMill to coexist with the tile server (/datasource, /tile) on external port 80.
   location /tile/ {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20008;
   
        
        #proxy_cache my-cache;
        #proxy_cache_valid  200 302  60m;
        #proxy_cache_valid  404      1m;
    }
    location /datasource/ {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20008;
    }
    #location /maps {
    # alias   /usr/share/nginx/www/Project-OSRM-Web/WebContent/;
    #}
   location /tilemill {
       rewrite     ^(.*)$ http://$IP:5002 permanent;
   }

   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20009;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}

server {
   #listen $IP:20008;
   listen 5002;
   server_name localhost;
   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20008;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}


FOF

sudo cp /tmp/sites-enabled-default /etc/nginx/sites-enabled/default
sudo service nginx restart

echo "Australia/Melbourne" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata
