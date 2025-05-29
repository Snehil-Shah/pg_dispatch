EXTENSION = pg_dispatch
EXTVERSION = 0.1.3
DATA = pg_dispatch--0.1.3.sql

PG_CONFIG ?= pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

.PHONY: dist docs
dist:
	mkdir -p dist
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o dist/$(EXTENSION)-$(EXTVERSION).zip HEAD

docs:
	bash scripts/update-docs.sh