echo Installing OSRM
source ./tm-settings

#dependencies:
sudo apt-get install -y "build-essential git cmake pkg-config libprotoc-dev libprotobuf7
protobuf-compiler libprotobuf-dev libosmpbf-dev libpng12-dev
libbz2-dev libstxxl-dev libstxxl-doc libstxxl1 libxml2-dev
libzip-dev libboost-all-dev lua5.1 liblua5.1-0-dev libluabind-dev libluajit-5.1-dev" 



git clone https://github.com/DennisOSRM/Project-OSRM.git ${osrm_dir}

cd ${osrm_dir}
mkdir -p build
cd build
cmake ..
make 
cd ..
rm profile.lua
#cp profiles/foot.lua profile.lua
ln -s profiles/${osrm_profile}.lua profile.lua

#cp ../../osrm/incoming.* .
#build/osrm-extract incoming.osm.pbf
#build/osrm-prepare incoming.osrm 
#build/osrm-routed -i cycletour.org -p 5010 -t 8 --hsgrdata incoming.osrm.hsgr --nodesdata incoming.osrm.nodes 
