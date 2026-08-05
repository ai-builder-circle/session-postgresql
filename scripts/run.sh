#!/usr/bin/env bash
if [ -z "$1" ]; then echo "usage: scripts/run.sh path/to/file.sql"; exit 1; fi
docker compose exec -T db psql -U forge -d freelanceforge -f "/repo/$1"
