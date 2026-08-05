# Module 06 — Subqueries & CTEs: queries inside queries

Goal: compose complex questions out of smaller queries, readably.

> `make reset` first.

## Mechanism: a query is just a table

The key insight: **the result of a `SELECT` is itself a table.** So anywhere SQL expects a table or a value, you can drop in another query. That's a subquery. A **CTE** (Common Table Expression, the `WITH` clause) is the same idea but *named and written up front*, which keeps big queries readable.

Three places a subquery lives:

1. **In `WHERE`** — as a value or a set: `WHERE budget > (SELECT avg(budget) FROM projects)`.
2. **In `FROM`** — as a derived table you then query further.
3. **`WITH name AS (...)`** — a CTE, referenced by name below. Prefer this once a subquery gets nested more than one level deep.

## Build & prove

**Scalar subquery — projects above the average budget:**
```sql
SELECT title, budget
FROM projects
WHERE budget > (SELECT avg(budget) FROM projects)
ORDER BY budget DESC;
```
The inner query returns one number (the average, 55 000); the outer query compares against it.

**Subquery returning a set with `IN`:**
```sql
-- clients who have at least one completed project
SELECT company_name
FROM clients
WHERE id IN (
    SELECT client_id FROM projects WHERE status = 'completed'
)
ORDER BY company_name;
```

**Correlated subquery** — the inner query references the outer row (runs once per outer row):
```sql
-- freelancers who earn more than the average rate
SELECT full_name, hourly_rate
FROM freelancers f
WHERE hourly_rate > (SELECT avg(hourly_rate) FROM freelancers)
ORDER BY hourly_rate DESC;
```

**`EXISTS` — does a related row exist?** Often clearer and faster than `IN`:
```sql
-- clients who have paid at least one invoice
SELECT c.company_name
FROM clients c
WHERE EXISTS (
    SELECT 1
    FROM projects p
    JOIN invoices i ON i.project_id = p.id
    JOIN payments pay ON pay.invoice_id = i.id
    WHERE p.client_id = c.id
)
ORDER BY c.company_name;
```

**CTE — the readable way.** Compute invoice totals once, then use them twice:
```sql
WITH invoice_totals AS (
    SELECT i.id AS invoice_id,
           i.status,
           sum(ii.quantity * ii.unit_price) AS total
    FROM invoices i
    JOIN invoice_items ii ON ii.invoice_id = i.id
    GROUP BY i.id, i.status
)
SELECT status,
       count(*)     AS num_invoices,
       sum(total)   AS billed
FROM invoice_totals
GROUP BY status
ORDER BY billed DESC;
```
The CTE `invoice_totals` behaves like a temporary table that exists only for this query. You built a per-invoice total, then aggregated *that* by status — two steps, each simple.

**Multiple CTEs chained** (each can use the previous):
```sql
WITH paid AS (
    SELECT invoice_id, sum(amount) AS paid_amount
    FROM payments GROUP BY invoice_id
),
billed AS (
    SELECT invoice_id, sum(quantity * unit_price) AS billed_amount
    FROM invoice_items GROUP BY invoice_id
)
SELECT b.invoice_id,
       b.billed_amount,
       coalesce(p.paid_amount, 0)              AS paid_amount,
       b.billed_amount - coalesce(p.paid_amount, 0) AS outstanding
FROM billed b
LEFT JOIN paid p ON p.invoice_id = b.invoice_id
ORDER BY outstanding DESC;
```
`coalesce(x, 0)` = "use x, but if it's NULL use 0" — essential when a LEFT JOIN produces NULLs. This query is a real accounts-receivable report: what's still owed on each invoice.

## Break it (on purpose): scalar subquery returns too many rows

```sql
SELECT title FROM projects
WHERE budget = (SELECT budget FROM projects);   -- inner returns 8 rows, not 1
```
Expected:
```
ERROR:  more than one row returned by a subquery used as an expression
```
A subquery used where a *single value* is expected must return exactly one row. Use `IN` (for a set) or add a `LIMIT 1` / aggregate to make it scalar.

## Exercises

1. Find projects whose budget is above the average budget *for their status* (correlated subquery).
2. List clients who have **no** invoices at all (use `NOT EXISTS` or `NOT IN`).
3. Using a CTE, compute each freelancer's total billed amount, then show only those above R60 000.
4. Rewrite the "clients with a completed project" query three ways: with `IN`, with `EXISTS`, and with a `JOIN` + `DISTINCT`. Confirm all three return the same rows.
5. Reproduce the "more than one row" error, then fix it.

Solution: `solutions/06.sql`.

## Checkpoint

You can compose queries from sub-parts and use CTEs to keep complex logic readable. Next: making all of this fast, and proving it.
