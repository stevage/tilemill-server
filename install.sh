#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# This script installs TileMill, PostGIS, nginx, and does some basic configuration.
# The set up it creates has basic security: port 20009 can only be accessed through port 80, which has password auth.

# Author: Steve Bennett

# load configurable settings.
source tm-settings
# Get number of cores and RAM
source ./getspecs.sh

if ! grep -q `hostname` /etc/hosts; then
  echo "127.0.0.1 `hostname`" | sudo tee -a /etc/hosts
fi

echo "Australia/Melbourne" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

sudo apt-get update

echo "Installing TileMill"

add-apt-repository -y ppa:developmentseed/mapbox
apt-get update
apt-get install -y tilemill

echo "Reconfiguring TileMill to allow local access through port 80."

export ip=`curl http://ifconfig.me`

cat > /etc/tilemill/tilemill.config <<FOF
{
  "files": "/usr/share/mapbox",
  "coreUrl": "$ip:80",
  "tileUrl": "$ip:80",
  "listenHost": "0.0.0.0",
  "server": true
}
FOF

#sudo start tilemill

# To tunnel to the machine, if needed:
# ssh -CA nectar-maps -L 21009:localhost:20009 -L 21008:localhost:20008
# Then access it at localhost:21009


./install-nginx.sh
sudo apt-get install -y unzip
echo "Let's get some fonts."
pushd /usr/share/fonts/truetype
wget -q http://www.fontsquirrel.com/fonts/download/CartoGothic-Std -O CartoGothic-Std.zip 
unzip CartoGothic-Std.zip
popd

start tilemill


echo "Tilemill installed and running."
./get-waterpolygons.sh

echo "Let's get OSM data in the background."
./install-postgis.sh

./update-data.sh
