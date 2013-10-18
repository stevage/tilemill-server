#!/bin/bash

# This script installs TileMill, PostGIS, nginx, and does some basic configuration.
# The set up it creates has basic security: port 20009 can only be accessed through port 80, which has password auth.

# The Postgres database tuning assumes 32 Gb RAM.

# Author: Steve Bennett

#Move postgres to this directory (if the default location is too small). Comment it out to not move it.

# load configurable settings. alternatively, set them all through environment variables.
if [ -z "$tm_dbusername" ]; then
source tm-settings
fi
# Get number of cores and RAM
source ./getspecs.sh


echo "127.0.0.1 `hostname`" | sudo tee -a /etc/hosts

sudo apt-get update

#As per https://github.com/gravitystorm/openstreetmap-carto
sudo apt-get install -y policykit-1 postgresql-9.1 libpq-dev postgis
# Check to make sure we haven't already run this.
if [ -n "$POSTGRESDIR" ] && [ ! -d "$POSTGRESDIR/postgresql" ]; then sudo bash <<FOF
echo Moving postgresql from /var/lib/postgresql to $POSTGRESDIR/postgresql

service postgresql stop
mkdir -p $POSTGRESDIR
service postgresql stop
cd /var/lib/
mv postgresql $POSTGRESDIR
ln -s $POSTGRESDIR/postgresql postgresql
chmod a+r $POSTGRESDIR
service postgresql start
FOF
fi

# Install OSM2pgsql
sudo apt-get install -y software-properties-common git unzip
sudo add-apt-repository -y ppa:kakrueger/openstreetmap
sudo apt-get update

# what if I skip this line?
###TODO
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get install -y osm2pgsql

#(leave all defaults)

#Install TileMill

sudo add-apt-repository -y ppa:developmentseed/mapbox
sudo apt-get update
sudo apt-get install -y tilemill

# === Unsecuring TileMill

export ip=`curl http://ifconfig.me`

sudo tee /etc/tilemill/tilemill.config <<FOF
{
  "files": "/usr/share/mapbox",
  "coreUrl": "$ip:80",
  "tileUrl": "$ip:80",
  "listenHost": "0.0.0.0",
  "server": true
}
FOF

sudo start tilemill

# To tunnel to the machine, if needed:
# ssh -CA nectar-maps -L 21009:localhost:20009 -L 21008:localhost:20008
# Then access it at localhost:21009

# Configure Postgres
# Argh - can't crack the right combination here. I give up in the end and just make ubuntu a superuser. Just needs
# to be able to modify the 'relation' spatial_ref_sys
sudo -u postgres psql <<FOF
CREATE ROLE $tm_dbusername WITH LOGIN CREATEDB UNENCRYPTED PASSWORD '$tm_dbpassword';
GRANT ALL ON SCHEMA public TO $tm_dbusername;
GRANT ALL ON ALL TABLES IN SCHEMA public TO $tm_dbusername;
ALTER USER $tm_dbusername WITH SUPERUSER;
FOF


# create GIS template
db=template_gis
sudo -su postgres bash <<EOF
createdb --encoding=UTF8 --owner=$tm_dbusername $db
psql -d postgres -c "UPDATE pg_database SET datistemplate='true' WHERE datname='$db'"

psql -d $db -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql > /dev/null
psql -d $db -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql > /dev/null
psql -d $db -f /usr/share/postgresql/9.1/contrib/postgis_comments.sql > /dev/null
psql -d $db -c "GRANT SELECT ON spatial_ref_sys TO PUBLIC;"
psql -d $db -c "GRANT ALL ON geometry_columns TO $tm_dbusername;"
psql -d $db -c "create extension hstore;"
EOF

sudo -u postgres createdb --template=$db gis

sudo -u postgres psql -d gis -c "GRANT ALL ON DATABASE gis TO $tm_dbusername;"

# sudo -su postgres bash -c 'createuser -d -a -P ubuntu'

#(password 'ubuntu') (blank doesn't work well...)




# ======== Postgres performance tuning
sudo tee -a /etc/postgresql/9.1/main/postgresql.conf <<FOF
# Settings tuned for TileMill
shared_buffers = $((MYMEM/4))GB
autovacuum = on
effective_cache_size = $((MYMEM/4))GB
work_mem = 128MB
maintenance_work_mem = 64MB
wal_buffers = 1MB

FOF

# ==== Automatic start 
sudo tee /etc/rc.local <<FOF
#!/bin/sh -e
sysctl -w kernel.shmmax=$((MYMEM/4 + 1))000000000
sysctl -w kernel.shmall=$((MYMEM/4 + 1))000000000
service postgresql start
start tilemill
service nginx start
exit 0
FOF

sudo source /etc/rc.local
sudo service postgresql reload

# === Securing with nginx
sudo apt-get -y install nginx

cd /etc/nginx
# This probably will break if the password contains bash-recognised characters, but I was defeated
# by escaping.
sudo bash <<FOF
printf "$tm_username:$(openssl passwd -crypt ""$tm_password"")\n" >> htpasswd
chown root:www-data htpasswd
chmod 640 htpasswd
FOF

# In the following config, http_host is literally a dollar sign then http_host
# whereas IP is a shell variable that should be substituted at the time the config is written.
sudo tee /etc/nginx/sites-enabled/default <<FOF

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
       rewrite     ^(.*)$ http://$ip:5002 permanent;
   }

   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20009;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}

server {
   #listen $ip:20008;
   listen 5002;
   server_name localhost;
   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20009;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}
FOF


sudo service nginx restart
echo "Let's get some fonts."
sudo bash <<EOF
cd /usr/share/fonts/truetype
wget http://www.fontsquirrel.com/fonts/download/CartoGothic-Std -O CartoGothic-Std.zip 
unzip CartoGothic-Std.zip
EOF
sudo restart tilemill

echo "Australia/Melbourne" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

echo "Tilemill installed and running."
#./get-waterpolygons.sh
#./update-data.sh

