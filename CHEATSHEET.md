# PostgreSQL Cheat Sheet

A one-page reference. Full explanations live in the module READMEs.

## psql meta-commands (no semicolon needed)
```
\l              list databases          \d table     describe a table
\c db           connect to db           \dt          list tables
\dn             list schemas            \di          list indexes
\dv             list views              \df          list functions
\x              toggle wide display     \timing      toggle query timing
\h SELECT       SQL help                \?           psql help        \q  quit
```

## DDL — defining structure
```sql
CREATE TABLE t (
  id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name    text NOT NULL,
  price   numeric(12,2) CHECK (price >= 0),
  ref_id  bigint REFERENCES other(id) ON DELETE CASCADE,
  made_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE t ADD COLUMN col text;
ALTER TABLE t ADD CONSTRAINT c UNIQUE (name);
DROP TABLE t CASCADE;
```

## Types worth knowing
`bigint` · `numeric(p,s)` (money!) · `text` · `varchar(n)` · `boolean` · `date` · `timestamptz` · `uuid`
Never use `real`/`float` for money.

## DML — data
```sql
INSERT INTO t (name, price) VALUES ('a', 10), ('b', 20);
UPDATE t SET price = price * 1.1 WHERE id = 1;
DELETE FROM t WHERE id = 1;
```

## Querying
```sql
SELECT col, other AS alias FROM t
WHERE cond AND (a OR b)
  AND x IN (1,2,3) AND y BETWEEN 1 AND 9
  AND name ILIKE '%foo%' AND z IS NULL
ORDER BY col DESC
LIMIT 10 OFFSET 20;
```
Evaluation order: FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.
(So WHERE can't see SELECT aliases.)

## Joins
```sql
FROM a JOIN b       ON a.id = b.a_id   -- inner: matches only
FROM a LEFT JOIN b  ON a.id = b.a_id   -- keep all a; b NULL if no match
-- find missing:
FROM a LEFT JOIN b ON ... WHERE b.id IS NULL
```

## Aggregation
```sql
SELECT grp, count(*), sum(x), avg(x), min(x), max(x)
FROM t GROUP BY grp HAVING count(*) > 1;
```
WHERE filters rows (before grouping); HAVING filters groups (after).

## Subqueries & CTEs
```sql
WHERE x > (SELECT avg(x) FROM t)          -- scalar
WHERE id IN (SELECT id FROM other)         -- set
WHERE EXISTS (SELECT 1 FROM o WHERE ...)   -- existence
WITH cte AS (SELECT ...) SELECT * FROM cte;-- named
coalesce(x, 0)  -- NULL -> 0
```

## Window functions (keep every row)
```sql
sum(x)      OVER (ORDER BY d)               -- running total
rank()      OVER (ORDER BY x DESC)          -- ranking
row_number()OVER (PARTITION BY g ORDER BY d)-- per-group counter
lag(x)      OVER (ORDER BY d)               -- previous row
```
Can't be used in WHERE — wrap in a subquery to filter on them.

## Indexes & EXPLAIN
```sql
CREATE INDEX idx ON t(col);
CREATE INDEX idx ON t(lower(email));   -- functional
EXPLAIN ANALYZE SELECT ...;            -- real plan + timing
```
Seq Scan = read everything (bad on big tables). Index Scan = used an index (good).
Index foreign keys. Don't wrap the indexed column in a function in WHERE.

## Transactions
```sql
BEGIN;
  ...
  SAVEPOINT sp;  ...  ROLLBACK TO sp;
COMMIT;   -- or ROLLBACK;
```
Any error aborts the whole transaction until you ROLLBACK.

## Views, functions, triggers
```sql
CREATE VIEW v AS SELECT ...;
CREATE MATERIALIZED VIEW mv AS SELECT ...;  REFRESH MATERIALIZED VIEW mv;

CREATE FUNCTION f(a int) RETURNS numeric AS $$ SELECT ...; $$ LANGUAGE sql;

CREATE FUNCTION g() RETURNS trigger AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg BEFORE UPDATE ON t FOR EACH ROW EXECUTE FUNCTION g();
```
Inside triggers: NEW = incoming row, OLD = previous row.

## Normalisation (rule of thumb)
Store every fact once. Aim for 3NF: no repeating groups, no partial-key dependencies,
no non-key column depending on another non-key column. Many-to-many → junction table.
