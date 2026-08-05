-- Module 07 solutions
CREATE TABLE IF NOT EXISTS events (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, user_id bigint, action text);
INSERT INTO events (user_id, action)
SELECT (random()*10000)::bigint, (ARRAY['login','click','purchase','logout'])[1+floor(random()*4)]
FROM generate_series(1,500000);
ANALYZE events;
-- 1 before/after index on action
EXPLAIN ANALYZE SELECT * FROM events WHERE action='purchase';
CREATE INDEX idx_events_action ON events(action);
ANALYZE events;
EXPLAIN ANALYZE SELECT * FROM events WHERE action='purchase';
-- 2 low selectivity: 'action' has 4 values, so ~25% of rows match; the index still
--   touches a quarter of the table, so the planner may even ignore it. 'user_id' has
--   ~10000 values, so each lookup matches ~0.01% of rows -> the index is hugely effective.
-- 4 functional index
CREATE INDEX idx_freelancers_lower_email ON freelancers (lower(email));
EXPLAIN ANALYZE SELECT * FROM freelancers WHERE lower(email)='thabo@example.co.za';
DROP TABLE events;
