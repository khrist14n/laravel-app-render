#!/usr/bin/env bash
set -e

echo "Running composer"
composer install --no-dev --working-dir=/var/www/html

echo "Caching config..."
php artisan config:cache

echo "Caching routes..."
php artisan route:cache

# The database is frequently still starting when this runs, so a failed
# connection is retried before it is treated as a real error.
echo "Running migrations..."
attempt=0
until php artisan migrate --force; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 30 ]; then
    echo "Migrations still failing after ${attempt} attempts"
    exit 1
  fi
  echo "Migration attempt ${attempt} failed, retrying in 5s..."
  sleep 5
done
