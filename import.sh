#!/bin/bash
osm2pgsql  -S customised.style --database gis_aus --slim --create --username ubuntu --hstore --hstore-match-only --number-processes 8 australia-latest.osm.pbf
