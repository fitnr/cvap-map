UGLIFY = node_modules/.bin/uglifyjs $(UGLIFYFLAGS)
UGLIFYFLAGS = -c -m
SMASH = node_modules/.bin/smash
TOPOJSON = node_modules/.bin/topojson

D3_LIBS = node_modules/d3/src/start.js \
		  node_modules/d3/src/selection/index.js \
		  node_modules/d3/src/scale/sqrt.js \
		  node_modules/d3/src/dsv/csv.js \
		  node_modules/d3/src/xhr/json.js \
		  node_modules/d3/src/geo/path.js \
		  node_modules/d3/src/geo/albers-usa.js \
		  node_modules/d3/src/end.js \
		  node_modules/topojson/topojson.min.js \
		  node_modules/queue-async/queue.min.js

assets/d3.min.js: $(D3_LIBS) | assets
	$(SMASH) $^ | $(UGLIFY) > $@

data/county.json: geo/tl_2013_us_county.geojson
	@rm -f $@
	mapshaper -i encoding=iso88591 $< -simplify 0.75% visvalingam cartesian -o format=topojson $@

geo/tl_2013_us_county.geojson: geo/tl_2013_us_county.shp
	ogr2ogr -f GeoJSON -sql "SELECT GEOID AS id, NAMELSAD AS n from $(basename $(<F))" $@ $<

geo/tl_2013_us_county.shp: geo/tl_2013_us_county.zip
	unzip $< -d $(@D)
	@touch $@

geo/tl_2013_us_county.zip: | geo
	curl ftp://ftp2.census.gov/geo/tiger/TIGER2013//COUNTY/tl_2013_us_county.zip > $@

data/cvap-county.csv: CVAP_CSV_Format_2009-2013/County.csv | data
	grep -E "(Total|CVAP_EST)" $^ | grep -v '05000US72' | csvcut -c GEOID,TOT_EST,CVAP_EST | \
	sed -e 's/05000US//g' > $@

CVAP_CSV_Format_2009-2013/%.csv: CVAP_CSV_Format_2009-2013.zip | CVAP_CSV_Format_2009-2013
	unzip -o $< $(@F) -d $(@D)
	@touch $@

CVAP_CSV_Format_2009-2013.zip:
	curl https://www.census.gov/rdo/pdf/CVAP_CSV_Format_2009-2013.zip > $@

assets data geo CVAP_CSV_Format_2009-2013:
	mkdir -p $@

install:
	npm install