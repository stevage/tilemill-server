#!/bin/bash
touch nohup.out
cmd=`cat <<EOF
rm -f australia-latest.osm.pbf
echo --- Downloading data.
wget -q http://download.geofabrik.de/openstreetmap/australia-oceania/australia-latest.osm.pbf
echo "--- Start importing into PostGIS"
./import.sh
echo "--- Start updating place table."
#./updateplaces.sh
./process.sh
#echo "--- Now updating OSRM routing tables."
#mv australia-latest.osm.pbf osrm
#./updateosrm.sh
EOF`
nohup bash -c "$cmd" &
# store the process id of the nohup process in a variable
CHPID=$!        

# whenever ctrl-c is pressed, kill the nohup process before exiting
trap "echo 'Abandoning import.' && kill -9 $CHPID" INT

tail -f nohup.out
