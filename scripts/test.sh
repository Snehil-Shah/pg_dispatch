#!/bin/bash

# Config
SRC_FILE="pg_dispatch.sql"
MIGRATIONS_DIR="test/supabase/migrations"
MIGRATION_NAME="pg_dispatch_init"

# Ensure migrations dir exists
mkdir -p "$MIGRATIONS_DIR"

# Generate timestamped filename
TIMESTAMP=$(date +%Y%m%d%H%M%S)
TARGET_FILE="$MIGRATIONS_DIR/${TIMESTAMP}_${MIGRATION_NAME}.sql"

# Skip the first line as it prevents it to be run as a SQL script
tail -n +2 "$SRC_FILE" > "$TARGET_FILE"

echo "Created migration file to initialize extension. Starting Supabase test environment..."
echo

# Initialize Supabase test environment
cd test || exit 1
npx supabase stop # sanity check
npx supabase start
npx supabase db reset

echo
echo "Supabase test environment ready. Running tests..."
echo

# Run tests
npx supabase test db
TEST_EXIT_CODE=$?

echo
echo "Tests completed with exit code $TEST_EXIT_CODE. Stopping test environment..."
echo

# Stop Supabase test environment
npx supabase stop

# Clean up migration file
cd ..
rm -f "$TARGET_FILE"

# Exit with the same code as the tests
exit $TEST_EXIT_CODE