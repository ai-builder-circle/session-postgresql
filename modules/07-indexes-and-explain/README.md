# Module 07 — Indexes & EXPLAIN: making it fast, and proving it

Goal: understand *why* queries are slow and *prove* that an index fixed it. This is the module that separates people who "know SQL" from people who can run a database.

> `make reset` first.

## Mechanism: an index is a sorted lookup structure

Without an index, finding rows that match `WHERE email = 'x'` forces Postgres to read **every row** in the table and check each one. That's a **sequential scan** (`Seq Scan`). Fine for 5 rows; catastrophic for 5 million.

An **index** is a separate, sorted data structure (a B-tree) that maps a column's values to the physical location of the matching rows — like the index at the back of a book. With it, Postgres jumps straight to the matches: an **index scan**.

The trade-off, and why you don't index everything:

- Indexes **speed up reads** that filter/sort/join on the indexed column.
- Indexes **slow down writes** — every `INSERT`/`UPDATE`/`DELETE` must also update the index.
- Indexes **take disk space**.

So: index the columns you frequently filter or join on (especially foreign keys), not every column.

## The tool: EXPLAIN and EXPLAIN ANALYZE

- `EXPLAIN <query>` — shows the *plan* Postgres would use (estimates only, doesn't run it).
- `EXPLAIN ANALYZE <query>` — actually runs it and reports *real* timings and row counts.

You read a plan bottom-up. The words to look for: **`Seq Scan`** (reads everything — suspicious on big tables) vs **`Index Scan`** / **`Bitmap Index Scan`** (used an index — good).

## Build & prove: watch a Seq Scan become an Index Scan

Our seed table is tiny, so let's create a genuinely large table to make the difference visible. In `psql`:

```sql
-- 500,000 fake events
CREATE TABLE events (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint,
    action  text
);

INSERT INTO events (user_id, action)
SELECT (random() * 10000)::bigint,      -- random user 0..10000
       (ARRAY['login','click','purchase','logout'])[1 + floor(random()*4)]
FROM generate_series(1, 500000);        -- generate_series makes 500k rows

ANALYZE events;   -- update the planner's statistics
```

**Before the index** — search by `user_id`:
```sql
EXPLAIN ANALYZE SELECT * FROM events WHERE user_id = 4242;
```
You'll see something like:
```
 Seq Scan on events  (cost=0.00..8455.00 rows=50 width=...) (actual time=0.3..40.1 rows=48 ...)
   Filter: (user_id = 4242)
   Rows Removed by Filter: 499952
 Planning Time: 0.1 ms
 Execution Time: ~40 ms
```
Read that: it scanned the whole table and **threw away hundreds of thousands of rows** to find ~50. That "Rows Removed by Filter" line is the smell of a missing index.

> On a multi-core machine you'll likely see `Gather` / `Workers Planned: 2` / `Parallel Seq Scan` instead of a plain `Seq Scan`. That just means Postgres split the full-table scan across CPU cores — it's *still* reading every row. The point stands: no index means scanning everything.

**Add the index:**
```sql
CREATE INDEX idx_events_user ON events(user_id);
```

**After the index** — same query:
```sql
EXPLAIN ANALYZE SELECT * FROM events WHERE user_id = 4242;
```
Now:
```
 Bitmap Heap Scan on events  ... (actual time=0.05..0.12 rows=48 ...)
   Recheck Cond: (user_id = 4242)
   ->  Bitmap Index Scan on idx_events_user  (actual time=0.03..0.03 rows=48 ...)
 Execution Time: ~0.2 ms
```
From ~40 ms to ~0.2 ms — a couple of hundred times faster — and the plan now uses `idx_events_user` instead of reading the whole table. **That drop in Execution Time is your runnable proof.** Your exact numbers will differ; the shape (Seq Scan → Index Scan, big time drop) will not.

## Why our schema already has indexes

Run `\di` to see the indexes on FreelanceForge. You'll notice `db/schema.sql` created indexes on every foreign key (`projects.client_id`, `invoices.project_id`, etc.). Foreign keys are joined on constantly, so indexing them is a near-automatic good decision. Primary keys and `UNIQUE` columns are indexed automatically — you never create those yourself.

## Break it (on purpose): the index Postgres ignores

Wrap the indexed column in a function and the index becomes useless:
```sql
EXPLAIN ANALYZE SELECT * FROM events WHERE user_id + 0 = 4242;
```
Back to a `Seq Scan` — because the index is on `user_id`, not on `user_id + 0`. Postgres can't match the expression to the index. Lesson: **keep the indexed column bare on one side of the comparison.** (This is also why `WHERE lower(email) = ...` won't use a plain index on `email` — you'd need an index on `lower(email)`.)

## Clean up the practice table

```sql
DROP TABLE events;
```

## Exercises

1. On a fresh `events` table (recreate it), time a query filtering by `action = 'purchase'` before and after adding an index on `action`. Note the execution times.
2. Explain (in a comment) why an index on `action` helps less than one on `user_id`, given only 4 distinct actions. (Hint: low *selectivity* — an index that still matches 25% of rows barely helps.)
3. Run `EXPLAIN` on the accounts-receivable CTE from Module 06. Identify which scans use indexes.
4. Create an index on `lower(email)` for `freelancers`, then show a query that uses it.

Solution: `solutions/07.sql`.

## Checkpoint

You can read a query plan, spot a missing index, add one, and *prove* the speedup with real timings. You also know why over-indexing hurts. Next: keeping money safe when things go wrong.
