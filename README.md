# WARNING - Obsolete

These scripts have been replaced by a newer, shinier, Salt-based deployment system called SaltyMill:

https://github.com/stevage/saltymill

SaltyMill does everything these scripts did, and a bit more.


```



















```
# Continue anyway?

These scripts don't work at all on Ubuntu 14.04 (Trusty). I don't remember if they still work on Precise.

## Ok then.

These scripts install TileMill and a stack of related services:

* TileMill
* Nginx (making TileMill accessible on port 80, with basic password auth)
* PostGIS (for loading OpenStreetMap data into)
* osm2pgsql (loads the OpenStreetMap data)
* Scripts to manage loading OSM data and refresh it with minimal downtime
* OSRM (routing engine)

```
sudo apt-get -y install git &&
git clone https://github.com/stevage/tilemill-server &&
cd tilemill-server

# Optionally, edit tm-settings

sudo nohup ./install.sh &
```

When done, TileMill is accessible on port 80: http://myserver
OSRM will be running by default on port 5010
