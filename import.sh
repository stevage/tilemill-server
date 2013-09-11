#!/bin/bash
osm2pgsql  -S customised.style --database gis --slim --create --username ubuntu --hstore --hstore-match-only --number-processes 8 --unlogged australia-latest.osm.pbf
# some of these will probably fail
psql -d gis <<EOF
CREATE INDEX idx_planet_osm_point_tags ON planet_osm_point USING gist(tags);
CREATE INDEX idx_planet_osm_polygon_tags ON planet_osm_polygon USING gist(tags);
CREATE INDEX idx_planet_osm_line_tags ON planet_osm_line USING gist(tags);

create index planet_osm_polygon_index on planet_osm_polygon using gist(way); 
CREATE INDEX planet_osm_line_index ON planet_osm_line USING gist(way);
CREATE INDEX planet_osm_roads_index ON planet_osm_roads USING gist(way);

create index planet_osm_roads_highways on planet_osm_roads (highway);
create index planet_osm_line_highways on planet_osm_line (highway);
EOF
