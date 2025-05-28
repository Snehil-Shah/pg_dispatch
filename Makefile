EXTENSION = pg_dispatch
EXTVERSION = 0.1.2
DATA = pg_dispatch--0.1.2.sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: dist
dist:
	mkdir -p dist
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o dist/$(EXTENSION)-$(EXTVERSION).zip HEAD