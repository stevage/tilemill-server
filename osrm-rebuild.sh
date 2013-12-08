source ./tm-settings
echo "Rebuilding OSRM index."
cd ${osrm_dir}
wget ${osm_extract_url} -O incoming.osm.pbf
build/osrm-extract incoming.osm.pbf
build/osrm-prepare incoming.osrm
echo "OSRM index rebuilt."
#nohup ./osrm-run.sh &
