source tm-settings
cd ${osrm_dir}
nohup build/osrm-routed -i ${osrm_host} -p ${osrm_port} -t 8 incoming.osrm & 
