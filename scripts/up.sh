#!/usr/bin/env bash
set -e
docker compose up -d
echo "Postgres starting on localhost:5433 (db=freelanceforge user=forge pass=forge)"
