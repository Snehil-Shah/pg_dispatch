#!/bin/bash

# Install mdextract globally
npm install -g mdextract

# Replace <docs> with include: pg_dispatch.sql in README.md
sed -i "s/<docs>/include: pg_dispatch.sql/g" README.md

# Run mdextract --update README.md
mdextract --update README.md

# Replace the include comments back to <docs>
sed -i "s/include: pg_dispatch\.sql/<docs>/g" README.md

echo "Documentation update complete!"