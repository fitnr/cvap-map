UGLIFY = node_modules/.bin/uglifyjs $(UGLIFYFLAGS)
UGLIFYFLAGS = -c -m
SMASH = node_modules/.bin/smash

D3_LIBS = node_modules/d3/src/start.js \
		  node_modules/d3/src/end.js

assets/d3.min.js: $(D3_LIBS) | assets
	$(SMASH) $^ | $(UGLIFY) > $@

data/cvap-county.csv: CVAP_CSV_Format_2009-2013/County.csv | data
	grep -E "(Total|CVAP_EST)" $^ | csvcut -c GEOID,TOT_EST,CVAP_EST > $@

CVAP_CSV_Format_2009-2013/%.csv: CVAP_CSV_Format_2009-2013.zip | CVAP_CSV_Format_2009-2013
	unzip -o $< $(@F) -d $(@D)
	@touch $@

CVAP_CSV_Format_2009-2013.zip:
	curl https://www.census.gov/rdo/pdf/CVAP_CSV_Format_2009-2013.zip > $@

assets data CVAP_CSV_Format_2009-2013:
	mkdir -p $@

install:
	npm install