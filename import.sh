#!/bin/bash
newdb=new
echo Creating new database.
createdb -T template_gis $newdb
source ./getspecs.sh
echo Importing with OSM2PGSQL
export cachesize=800
if [ "$MYMEM" -ge 16 ]; then
  export cachesize=4000
fi
osm2pgsql  -S customised.style --database $newdb --slim --create --username ubuntu --hstore --number-processes $MYCORES --unlogged --cache $cachesize australia-latest.osm.pbf
# some of these will probably fail
echo Creating indexes
psql -d $newdb <<EOF
CREATE INDEX idx_planet_osm_point_tags ON planet_osm_point USING gist(tags);
CREATE INDEX idx_planet_osm_polygon_tags ON planet_osm_polygon USING gist(tags);
CREATE INDEX idx_planet_osm_line_tags ON planet_osm_line USING gist(tags);

create index planet_osm_polygon_index on planet_osm_polygon using gist(way); 
CREATE INDEX planet_osm_line_index ON planet_osm_line USING gist(way);
CREATE INDEX planet_osm_roads_index ON planet_osm_roads USING gist(way);

create index planet_osm_roads_highways on planet_osm_roads (highway);
create index planet_osm_line_highways on planet_osm_line (highway);
EOF
echo Cutting over to new database - all connections will be terminated.
psql -d postgres <<EOF
DROP DATABASE gis_old;
select pg_terminate_backend(procpid) from pg_stat_activity where datname='gis';
ALTER DATABASE gis RENAME TO gis_old;
ALTER DATABASE $newdb RENAME TO gis;
EOF

