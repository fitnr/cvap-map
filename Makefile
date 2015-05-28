UGLIFY = node_modules/.bin/uglifyjs $(UGLIFYFLAGS)
UGLIFYFLAGS = -c -m
SMASH = node_modules/.bin/smash
TOPOJSON = node_modules/.bin/topojson

D3_LIBS = node_modules/d3/src/start.js \
		  node_modules/d3/src/selection/index.js \
		  node_modules/d3/src/scale/threshold.js \
		  node_modules/d3/src/scale/sqrt.js \
		  node_modules/d3/src/dsv/csv.js \
		  node_modules/d3/src/xhr/json.js \
		  node_modules/d3/src/geo/path.js \
		  node_modules/d3/src/format/index.js \
		  node_modules/d3/src/geo/albers-usa.js \
		  node_modules/d3/src/end.js \
		  node_modules/topojson/topojson.min.js

assets/d3.min.js: $(D3_LIBS) | assets
	$(SMASH) $^ | $(UGLIFY) > $@

data/us-cvap.json: geo/states.shp geo/counties.shp
	mapshaper combine-files id-field=id encoding=iso88591 $^ -simplify 2% -o format=topojson $@

geo/states.shp: geo/cb_2013_us_state_20m.shp
	@rm -f $@
	ogr2ogr -f 'ESRI Shapefile' -sql "SELECT GEOID AS id from $(basename $(<F))" -nln states $@ $<

geo/counties.shp: geo/cb_2013_us_county_20m.shp data/cvapcounty.csv
	@rm -f $@
	ogr2ogr -f 'ESRI Shapefile' \
		-sql "SELECT $(basename $(<F)).GEOID AS id, $(basename $(<F)).NAME AS n, CAST(cvapcounty.TOT_EST AS INTEGER(16)) total, CAST(cvapcounty.CVAP_EST AS INTEGER(16)) voters \
		FROM $(basename $(<F)) LEFT JOIN 'data/cvapcounty.csv'.cvapcounty ON $(basename $(<F)).GEOID = cvapcounty.GEOID" \
		-nln counties $@ $<

geo/%.shp: geo/%.zip
	unzip $< -d $(@D)
	@touch $@

geo/%.zip: | geo
	curl http://www2.census.gov/geo/tiger/GENZ2013/$*.zip > $@

data/cvapcounty.csv: CVAP_CSV_Format_2009-2013/County.csv | data
	iconv -f iso-8859-1 -t utf-8 $^ | \
	grep -E "(Total|CVAP_EST)" | \
	grep -v '05000US72' | \
	csvcut -c GEOID,TOT_EST,CVAP_EST | \
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