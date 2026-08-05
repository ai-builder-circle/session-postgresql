-- Rebuilds the entire finished database in one shot.
-- Used by `make reset`. Loads the full schema, then the seed data.
\echo 'Loading schema...'
\i /repo/db/schema.sql
\echo 'Loading seed data...'
\i /repo/db/seed.sql
\echo 'Done. Database is at a clean, fully-built state.'
