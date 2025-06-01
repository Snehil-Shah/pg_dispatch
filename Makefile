EXTENSION = pg_dispatch
EXTVERSION = $(shell grep default_version $(EXTENSION).control | sed "s/default_version = '\(.*\)'/\1/")
DATA = $(EXTENSION)--$(EXTVERSION).sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: prepare clean docs test
prepare:
	make clean
	cp pg_dispatch.sql $(EXTENSION)--$(EXTVERSION).sql
	sed 's/@VERSION@/$(EXTVERSION)/g' META.json.in > META.json

clean:
	rm -f META.json
	rm -f $(EXTENSION)--*.sql

docs:
	bash scripts/update-docs.sh

test:
	bash scripts/test.sh
