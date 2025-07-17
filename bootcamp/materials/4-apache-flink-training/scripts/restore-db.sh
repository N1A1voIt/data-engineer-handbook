#!/bin/bash
set -e

echo "Starting database restore..."

# Wait a bit to ensure postgres is fully ready
sleep 2

# Check if dump file exists
if [ ! -f /tmp/db_backup.dump ]; then
    echo "No dump file found at /tmp/db_backup.dump, skipping restore"
    exit 0
fi

# Test connection first
echo "Testing database connection..."
until pg_isready -h flink-postgres -p 5432 -U postgres -d postgres; do
    echo "Waiting for database to be ready..."
    sleep 2
done

# Restore the database
echo "Restoring database from dump..."
pg_restore --verbose --clean --no-acl --no-owner \
    -h flink-postgres -U postgres -d postgres \
    /tmp/db_backup.dump

if [ $? -eq 0 ]; then
    echo "Database restore completed successfully"
else
    echo "Database restore failed, but continuing..."
fi

echo "Init complete"