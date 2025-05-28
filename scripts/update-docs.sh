#!/bin/bash

# Install mdextract globally
npm install -g mdextract

# Read the control file and extract default version
default_version=$(grep "default_version" pg_dispatch.control | sed "s/.*'\(.*\)'.*/\1/")

echo "Found default version: $default_version"

# Replace <docs> with include: pg_dispatch--{version}.sql in README.md
sed -i "s/<docs>/include: pg_dispatch--$default_version.sql/g" README.md

# Run mdextract --update README.md
mdextract --update README.md

# Replace the include comments back to <docs>
sed -i "s/include: pg_dispatch--$default_version\.sql/<docs>/g" README.md

echo "Documentation update complete!"