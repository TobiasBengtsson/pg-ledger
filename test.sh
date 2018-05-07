#!/bin/sh
set -e

docker run --name postgres-test -d postgres:10.3

cat src/migrations/*.pgsql > migrations.pgsql

docker cp migrations.pgsql postgres-test:/tmp
docker cp src/db.pgsql postgres-test:/tmp

# So that PG has time to initialize
sleep 10

# Create DB from main script to make sure the script works
docker exec postgres-test sh -c 'psql postgres -U postgres -c "CREATE DATABASE pgledger_from_db"'
docker exec postgres-test sh -c 'psql -d pgledger_from_db -U postgres -f /tmp/db.pgsql'

# Create DB from migrations to make sure the script works
docker exec postgres-test sh -c 'psql postgres -U postgres -c "CREATE DATABASE pgledger_from_migrations"'
docker exec postgres-test sh -c 'psql -d pgledger_from_migrations -U postgres -f /tmp/migrations.pgsql'

# Dump DB from main script
docker exec postgres-test sh -c 'pg_dump -U postgres pgledger_from_db > /tmp/db_dump.pgsql'

# Dump DB from migrations
docker exec postgres-test sh -c 'pg_dump -U postgres pgledger_from_migrations > /tmp/migrations_dump.pgsql'

# Compare files for equality (will exit with error code if not equal)
docker exec postgres-test sh -c 'cmp /tmp/db_dump.pgsql /tmp/migrations_dump.pgsql'

# Tear down container
docker stop postgres-test
docker rm postgres-test
