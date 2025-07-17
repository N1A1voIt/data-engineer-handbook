#!/bin/bash
set -e

# Wait for Postgres to be ready
until pg_isready -h localhost -p 5432; do
  echo "Waiting for Postgres to start..."
  sleep 1
done

echo "Postgres is ready, restoring dump..."

# Restore the dump (adjust path if needed)
pg_restore --verbose --clean --no-acl --no-owner -U "$POSTGRES_USER" -d "$POSTGRES_DB" /docker-entrypoint-initdb.d/db_backup.dump

echo "Restore finished."
