#!/bin/sh
set -e

cat /tmp/source/src/migrations/*.pgsql > /tmp/source/migrations.pgsql

# Create DB from main script (this is the main database)
sh -c 'psql postgres -U postgres -c "CREATE DATABASE pgledger"'
sh -c 'psql -d pgledger -U postgres -f /tmp/source/src/db.pgsql'

# Create DB from migrations to make sure this script works too
sh -c 'psql postgres -U postgres -c "CREATE DATABASE pgledger_from_migrations"'
sh -c 'psql -d pgledger_from_migrations -U postgres -f /tmp/source/migrations.pgsql'

# Dump DB from main script
sh -c 'pg_dump -U postgres pgledger > /tmp/db_dump.pgsql'

# Dump DB from migrations
sh -c 'pg_dump -U postgres pgledger_from_migrations > /tmp/migrations_dump.pgsql'

# Compare files for equality (will exit with error code if not equal)
sh -c 'cmp /tmp/db_dump.pgsql /tmp/migrations_dump.pgsql'

# Install pgTAP to main database
sh -c 'psql -d pgledger -U postgres -c "CREATE EXTENSION pgtap"'

# Run tests
sh -c 'pg_prove -d pgledger -U postgres /tmp/source/tests/ --ext .pgsql --recurse --verbose'
