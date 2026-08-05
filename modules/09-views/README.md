# Module 09 — Views: saved queries you can reuse

Goal: name a complex query so you (and your app) can reuse it like a table.

> `make reset` first.

## Mechanism: a view is a stored query, not stored data

A **view** is a named `SELECT`. Querying the view re-runs that `SELECT` every time — the view holds *no data of its own*, it's a live window onto the underlying tables. Benefits: hide complexity behind a simple name, present a cleaned-up shape to your app, and keep one canonical definition of "what an invoice total is."

A **materialised view** is different: it runs the query *once* and stores the *result* on disk, like a cached snapshot. Reads are then instant, but the data is frozen until you `REFRESH` it. Use a plain view for always-fresh; a materialised view for expensive reports you can afford to refresh periodically.

## Build & prove: a view for invoice totals

The "sum the line items" query appears everywhere. Name it once:
```sql
CREATE VIEW invoice_totals AS
SELECT i.id           AS invoice_id,
       i.project_id,
       i.status,
       round(sum(ii.quantity * ii.unit_price), 2) AS total
FROM invoices i
JOIN invoice_items ii ON ii.invoice_id = i.id
GROUP BY i.id, i.project_id, i.status;
```
Now query it like any table:
```sql
SELECT * FROM invoice_totals ORDER BY invoice_id;
```
Expected (totals computed from the seeded line items):
```
 invoice_id | project_id |  status  |  total
------------+------------+----------+----------
          1 |          1 | paid     | 25000.00
          2 |          3 | paid     | 45000.00
          3 |          5 | paid     | 15000.00
          4 |          8 | paid     | 40000.00
          5 |          2 | unpaid   | 60000.00
          6 |          4 | overdue  | 35000.00
          7 |          6 | unpaid   | 60000.00
```

**Compose on top of the view** — outstanding balance report, built cleanly:
```sql
CREATE VIEW invoice_balances AS
SELECT t.invoice_id,
       t.status,
       t.total,
       coalesce(sum(p.amount), 0)          AS paid,
       t.total - coalesce(sum(p.amount),0) AS outstanding
FROM invoice_totals t
LEFT JOIN payments p ON p.invoice_id = t.invoice_id
GROUP BY t.invoice_id, t.status, t.total
ORDER BY outstanding DESC;

SELECT * FROM invoice_balances;
```
A view built on a view — each layer stays simple. This `invoice_balances` is exactly the kind of object your application would `SELECT *` from to render an accounts page.

## Materialised view: cache an expensive report

```sql
CREATE MATERIALIZED VIEW client_revenue AS
SELECT c.id AS client_id,
       c.company_name,
       coalesce(sum(pay.amount), 0) AS lifetime_revenue
FROM clients c
LEFT JOIN projects pr  ON pr.client_id = c.id
LEFT JOIN invoices i   ON i.project_id = pr.id
LEFT JOIN payments pay ON pay.invoice_id = i.id
GROUP BY c.id, c.company_name;

SELECT * FROM client_revenue ORDER BY lifetime_revenue DESC;
```
It reads instantly because the numbers are stored. But add a new payment and re-query — **the number won't change** until you refresh:
```sql
INSERT INTO payments (invoice_id, amount) VALUES (5, 10000);
SELECT * FROM client_revenue ORDER BY lifetime_revenue DESC;  -- unchanged!
REFRESH MATERIALIZED VIEW client_revenue;
SELECT * FROM client_revenue ORDER BY lifetime_revenue DESC;  -- now updated
```
That staleness *is* the trade-off you're accepting for speed. Clean up: `DELETE FROM payments WHERE invoice_id = 5 AND amount = 10000; REFRESH MATERIALIZED VIEW client_revenue;`

## Break it (on purpose): updating through a complex view

Try to insert into the aggregating view:
```sql
INSERT INTO invoice_totals (invoice_id, total) VALUES (99, 100);
```
Expected:
```
ERROR:  cannot insert into view "invoice_totals"
DETAIL:  Views that ... have GROUP BY ... are not automatically updatable.
```
Views with joins/aggregates are read-only by default (which is fine — you write to the base tables). *Simple* single-table views can be written through; complex ones can't unless you add special rules.

## Exercises

1. Create a view `active_projects` showing project title, client company, and freelancer name for projects with status `'active'`.
2. Create a view `overdue_invoices` listing invoice id, project title, client, and days overdue (`current_date - due_on`).
3. Query `invoice_balances` for only invoices where `outstanding > 0`.
4. Create a materialised view of "projects per freelancer", refresh it after inserting a new project, and confirm the count changes only after refresh.

Solution: `solutions/09.sql`.

## Checkpoint

You can package complex queries as reusable views and understand the fresh-vs-cached trade-off of materialised views. Next: making the database enforce logic and react automatically.
