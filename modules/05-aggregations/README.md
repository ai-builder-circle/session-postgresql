# Module 05 — Aggregations: many rows into one number

Goal: compute counts, sums, averages, and per-group summaries — the heart of reporting.

> `make reset` first.

## Mechanism: GROUP BY collapses rows into buckets

An **aggregate function** (`count`, `sum`, `avg`, `min`, `max`) eats many rows and returns one value. On its own it collapses the *whole* table to a single row:
```sql
SELECT count(*), avg(hourly_rate) FROM freelancers;
```

`GROUP BY` changes the unit: instead of one bucket for the whole table, you get one bucket **per distinct value** of the grouping column, and the aggregate runs inside each bucket.

The iron rule: **every column in `SELECT` must be either (a) in the `GROUP BY`, or (b) inside an aggregate.** Anything else is ambiguous ("which row's value did you want?") and Postgres rejects it.

`WHERE` vs `HAVING`: `WHERE` filters *rows before grouping*; `HAVING` filters *groups after aggregating*. You cannot put an aggregate in `WHERE`.

## Build & prove

**Whole-table aggregates:**
```sql
SELECT count(*)        AS num_freelancers,
       round(avg(hourly_rate), 2) AS avg_rate,
       min(hourly_rate) AS cheapest,
       max(hourly_rate) AS priciest
FROM freelancers;
```
Expected:
```
 num_freelancers | avg_rate | cheapest | priciest
-----------------+----------+----------+----------
               5 |   820.00 |   500.00 |  1200.00
```

**Per-group: projects per status:**
```sql
SELECT status, count(*) AS n
FROM projects
GROUP BY status
ORDER BY n DESC, status;
```
Expected:
```
  status   | n
-----------+---
 completed | 4
 active    | 3
 draft     | 1
```

**Money report: total collected per client** (joins + aggregate together — this is real reporting):
```sql
SELECT c.company_name, sum(pay.amount) AS collected
FROM clients c
JOIN projects pr  ON pr.client_id = c.id
JOIN invoices i   ON i.project_id = pr.id
JOIN payments pay ON pay.invoice_id = i.id
GROUP BY c.company_name
ORDER BY collected DESC;
```
Expected:
```
   company_name    | collected
-------------------+-----------
 Brightwave Studio |  45000.00
 Kagiso Media      |  45000.00
 Loop Fintech      |  40000.00
 Savanna Foods     |  15000.00
```
(Nordic Craft has no payments, so an inner join drops it — swap to `LEFT JOIN` if you want it shown as NULL/0.)

**HAVING: only clients who've paid more than R40 000:**
```sql
SELECT c.company_name, sum(pay.amount) AS collected
FROM clients c
JOIN projects pr  ON pr.client_id = c.id
JOIN invoices i   ON i.project_id = pr.id
JOIN payments pay ON pay.invoice_id = i.id
GROUP BY c.company_name
HAVING sum(pay.amount) > 40000
ORDER BY collected DESC;
```
Only Brightwave and Kagiso survive. Note the filter uses the aggregate — that's why it must be `HAVING`, not `WHERE`.

**Invoice totals from line items** (sum of quantity × price):
```sql
SELECT i.id AS invoice_id,
       sum(ii.quantity * ii.unit_price) AS invoice_total
FROM invoices i
JOIN invoice_items ii ON ii.invoice_id = i.id
GROUP BY i.id
ORDER BY i.id;
```

## Break it (on purpose): the GROUP BY rule

```sql
SELECT status, title, count(*) FROM projects GROUP BY status;
```
Expected:
```
ERROR:  column "projects.title" must appear in the GROUP BY clause or be used in an aggregate function
```
`title` is neither grouped nor aggregated, so Postgres can't know which title to show per status. Either add `title` to `GROUP BY` or wrap it (e.g. `max(title)`).

## Exercises

1. Average project budget per project status.
2. For each freelancer, the number of projects and the total budget across them (join + group).
3. Total invoiced amount (from `invoice_items`) per project, showing the project title.
4. Using `HAVING`, list only freelancers with 2 or more projects.
5. Trigger the GROUP BY error, then fix it two ways (add to GROUP BY vs wrap in an aggregate).

Solution: `solutions/05.sql`.

## Checkpoint

You can produce real summary reports and you know exactly when to use `WHERE` vs `HAVING`. Next: building queries out of other queries.
