#!/bin/bash
source ./tm-settings
rm -f australia-latest.osm.pbf
echo --- Downloading data.
#wget -q http://download.geofabrik.de/openstreetmap/australia-oceania/australia-latest.osm.pbf
wget -q ${osm_extract_url} -O incoming.osm.pbf
echo "--- Start importing into PostGIS"
./import.sh
echo "--- Start updating place table."
#./updateplaces.sh
./process.sh
#echo "--- Now updating OSRM routing tables."
#mv australia-latest.osm.pbf osrm
#./updateosrm.sh
