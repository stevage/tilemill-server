#!/bin/bash
cd osrm
./osrm-extract australia-latest.osm.pbf
./osrm-prepare australia-latest.osrm australia-latest.osrm.restrictions
