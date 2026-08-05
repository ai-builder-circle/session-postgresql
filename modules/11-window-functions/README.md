# Module 11 — Window Functions: analytics without collapsing rows

Goal: compute running totals, rankings, and per-group calculations while *keeping every row*. This is the tool that makes SQL genuinely powerful for analytics.

> `make reset` first.

## Mechanism: aggregate, but keep the rows

A `GROUP BY` aggregate **collapses** a group into one row. A **window function** computes across a set of rows too — but **returns a value for every row**, leaving them all visible. You get the detail *and* the summary in the same result.

The magic word is `OVER`. `sum(amount) OVER (...)` means "sum amount across a window of rows, and attach the result to each row." Inside `OVER` you control the window:

- `PARTITION BY x` — restart the calculation for each distinct `x` (like GROUP BY, but non-collapsing).
- `ORDER BY y` — define an order, which enables *running* calculations (each row sees rows up to itself).

The common functions:

| Function                        | Gives you                                             |
|---------------------------------|-------------------------------------------------------|
| `row_number()`                  | 1,2,3… position within the window                     |
| `rank()` / `dense_rank()`       | ranking, with/without gaps on ties                    |
| `sum/avg/count() OVER (...)`    | running or partitioned aggregates                     |
| `lag(col)` / `lead(col)`        | the previous / next row's value                       |
| `first_value` / `last_value`    | the first / last value in the window                  |

## Build & prove

**Running total of payments over time** — the canonical example:
```sql
SELECT paid_at::date AS day,
       amount,
       sum(amount) OVER (ORDER BY paid_at) AS running_total
FROM payments
ORDER BY paid_at;
```
Expected:
```
    day     |  amount  | running_total
------------+----------+---------------
 2026-07-11 | 25000.00 |      25000.00
 2026-07-21 | 45000.00 |      70000.00
 2026-07-31 | 15000.00 |      85000.00
 2026-08-02 | 20000.00 |     105000.00
 2026-08-04 | 40000.00 |     145000.00
```
(Your dates depend on when you seed, since the seed uses `now() - interval`. The *running_total* column — each row adding to the last — is the point.) Every payment row is still present, and each carries the cumulative sum up to that moment.

**Rank freelancers by rate** — keep all rows, add a ranking:
```sql
SELECT full_name,
       hourly_rate,
       rank() OVER (ORDER BY hourly_rate DESC) AS rate_rank
FROM freelancers;
```
Naledi is rank 1, Lerato 2, Aisha 3, and so on — but you still see the whole roster, not just the top one.

**PARTITION BY — number each client's projects independently:**
```sql
SELECT c.company_name,
       p.title,
       row_number() OVER (PARTITION BY c.id ORDER BY p.created_at) AS project_no
FROM projects p
JOIN clients c ON c.id = p.client_id
ORDER BY c.company_name, project_no;
```
The counter resets to 1 for each new client. That "reset per group" is exactly what `PARTITION BY` does.

**lag() — compare each payment to the previous one:**
```sql
SELECT paid_at::date AS day,
       amount,
       lag(amount) OVER (ORDER BY paid_at)          AS prev_amount,
       amount - lag(amount) OVER (ORDER BY paid_at) AS change
FROM payments
ORDER BY paid_at;
```
The first row's `prev_amount` is NULL (nothing before it) — that's correct, not a bug.

**Top project per freelancer** (window in a subquery — a very common real pattern):
```sql
SELECT full_name, title, budget
FROM (
    SELECT f.full_name, p.title, p.budget,
           row_number() OVER (PARTITION BY f.id ORDER BY p.budget DESC) AS rn
    FROM freelancers f
    JOIN projects p ON p.freelancer_id = f.id
) ranked
WHERE rn = 1
ORDER BY full_name;
```
For each freelancer, keep only their highest-budget project. You can't do this cleanly with `GROUP BY` alone — window functions are the right tool.

## GROUP BY vs window — see them side by side

```sql
-- GROUP BY: one row per status (detail lost)
SELECT status, sum(amount) FROM payments p
JOIN invoices i ON i.id = p.invoice_id
GROUP BY status;

-- Window: every payment row kept, with its status-total attached
SELECT p.id, i.status, p.amount,
       sum(p.amount) OVER (PARTITION BY i.status) AS status_total
FROM payments p
JOIN invoices i ON i.id = p.invoice_id
ORDER BY i.status, p.id;
```
Same numbers, different shape. Choose collapse (`GROUP BY`) or keep-detail (`OVER`) based on what the report needs.

## Break it (on purpose): window functions can't go in WHERE

```sql
SELECT full_name, rank() OVER (ORDER BY hourly_rate DESC) AS r
FROM freelancers
WHERE rank() OVER (ORDER BY hourly_rate DESC) = 1;
```
Expected:
```
ERROR:  window functions are not allowed in WHERE
```
Window functions are computed *after* `WHERE` (in the `SELECT` stage). To filter on one, wrap the query and filter outside — exactly the subquery pattern used in the "top project per freelancer" example above.

## Exercises

1. Show each invoice's total (from items) alongside the running total of invoice totals ordered by `issued_on`.
2. Rank clients by lifetime revenue using `dense_rank()`, keeping all clients visible.
3. For each freelancer, show their projects numbered by creation order (`row_number` + `PARTITION BY`).
4. Use `lag()` to show, for each client's projects ordered by date, the budget difference from their previous project.
5. Find the single most expensive project per client using the window-in-subquery pattern.

Solution: `solutions/11.sql`.

## Checkpoint

You can compute running totals, rankings, and per-partition analytics while keeping full detail — and you know why window filters need a subquery. Next: tie it all together and pressure-test the whole database.
