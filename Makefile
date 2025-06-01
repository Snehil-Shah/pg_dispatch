EXTENSION = pg_dispatch
EXTVERSION = $(shell grep default_version $(EXTENSION).control | sed "s/default_version = '\(.*\)'/\1/")
DATA = $(EXTENSION)--$(EXTVERSION).sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: prepare dist docs test
prepare:
	cp pg_dispatch.sql $(EXTENSION)--$(EXTVERSION).sql
	sed 's/@VERSION@/$(EXTVERSION)/g' META.json.in > META.json

dist:
	make prepare
	mkdir -p dist
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o dist/$(EXTENSION)-$(EXTVERSION).zip HEAD

clean:
	rm -rf dist/
	rm -f META.json
	rm -f $(EXTENSION)--*.sql

docs:
	bash scripts/update-docs.sh

test:
	bash scripts/test.sh