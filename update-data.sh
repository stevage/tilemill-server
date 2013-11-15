#!/bin/bash
cmd='
rm -f australia-latest.osm.pbf
wget http://download.geofabrik.de/openstreetmap/australia-oceania/australia-latest.osm.pbf
echo "--- Start importing into PostGIS"
./import.sh
echo "--- Start updating place table."
#./updateplaces.sh
./process.sh
#echo "--- Now updating OSRM routing tables."
#mv australia-latest.osm.pbf osrm
#./updateosrm.sh
'
nohup bash -c "$cmd" &
tail -f nohup.out
