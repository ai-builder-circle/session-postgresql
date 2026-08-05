# Module 03 — Querying: getting exactly what you want

Goal: retrieve precise slices of data with `SELECT`, `WHERE`, `ORDER BY`, and friends.

> From here on we work against the **full seeded database**. Load it now:
> ```bash
> make reset
> ```
> This gives you 5 freelancers, 5 clients, 8 projects, invoices, and payments to query.

## Mechanism: how a SELECT is evaluated

You *write* a query top-to-bottom (`SELECT ... FROM ... WHERE ...`), but Postgres *evaluates* it in a different order. Understanding this order removes 90% of beginner confusion:

1. **`FROM`** — pick the table(s).
2. **`WHERE`** — throw away rows that fail the condition.
3. **`GROUP BY`** — (Module 05) collapse rows into groups.
4. **`HAVING`** — (Module 05) throw away groups.
5. **`SELECT`** — compute the output columns.
6. **`ORDER BY`** — sort the surviving rows.
7. **`LIMIT` / `OFFSET`** — keep only some.

The practical consequence: `WHERE` runs *before* `SELECT`, so `WHERE` cannot use a column alias you invented in `SELECT`. That error will make sense now.

## Build & prove: work through these against the seeded data

**Everything, all columns:**
```sql
SELECT * FROM freelancers;
```

**Specific columns, filtered:**
```sql
SELECT full_name, hourly_rate
FROM freelancers
WHERE hourly_rate > 700;
```
Expected:
```
  full_name    | hourly_rate
---------------+-------------
 Aisha Patel   |      800.00
 Lerato Dlamini|      950.00
 Naledi Botha  |     1200.00
```

**Combine conditions with AND / OR:**
```sql
SELECT full_name, hourly_rate, is_available
FROM freelancers
WHERE hourly_rate > 700 AND is_available = true;
```
Lerato drops out (she's unavailable). You get Aisha and Naledi.

**Sort and limit — the 2 highest earners:**
```sql
SELECT full_name, hourly_rate
FROM freelancers
ORDER BY hourly_rate DESC
LIMIT 2;
```
Expected: Naledi (1200), Aisha (800).

**Pattern matching with LIKE / ILIKE** (`ILIKE` = case-insensitive):
```sql
SELECT company_name FROM clients WHERE company_name ILIKE '%studio%';
```
Returns `Brightwave Studio`. `%` matches any run of characters, `_` matches exactly one.

**Set membership with IN, ranges with BETWEEN:**
```sql
SELECT title, status FROM projects
WHERE status IN ('active','completed');

SELECT title, budget FROM projects
WHERE budget BETWEEN 40000 AND 80000
ORDER BY budget;
```

**NULL is special — use IS NULL, never `= NULL`:**
```sql
SELECT company_name, contact_email FROM clients WHERE contact_email IS NULL;
```
(Returns nothing here — every seeded client has an email — but the pattern is essential. `something = NULL` is never true, even when the value is null, because NULL means "unknown".)

**DISTINCT — unique values only:**
```sql
SELECT DISTINCT status FROM projects ORDER BY status;
```
Expected: `active`, `completed`, `draft`.

## Break it (on purpose): the alias trap

```sql
SELECT full_name, hourly_rate * 8 AS daily_rate
FROM freelancers
WHERE daily_rate > 5000;
```
Expected:
```
ERROR:  column "daily_rate" does not exist
```
Because `WHERE` runs before `SELECT`, the alias doesn't exist yet. Fix it by repeating the expression (`WHERE hourly_rate * 8 > 5000`) or wrapping in a subquery (Module 06).

## Exercises

1. List every project with a budget of at least R50 000, showing title and budget, most expensive first.
2. Find all freelancers whose name contains the letter "a" (case-insensitive), sorted alphabetically.
3. Show the 3 most recently created projects (hint: `ORDER BY created_at DESC LIMIT 3`).
4. Find all `unpaid` or `overdue` invoices, cheapest due-date first.
5. Cause the alias-in-WHERE error yourself, then rewrite the query two different ways so it works.

Solution: `solutions/03.sql`.

## Checkpoint

You can filter, sort, limit, pattern-match, and handle NULLs — and you understand the real evaluation order. Next: pulling data from several tables at once.
