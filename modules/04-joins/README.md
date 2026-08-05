# Module 04 — Joins: connecting the tables

Goal: combine rows from multiple tables into one result. This is where a relational database earns its name.

> Make sure the full data is loaded: `make reset`.

## Mechanism: a join is a filtered cross-product

Imagine pairing *every* freelancer with *every* project — that's the cross product (a huge grid). A **join condition** (`ON f.id = p.freelancer_id`) then keeps only the pairs that actually belong together. That's all a join is: form pairs, keep the matching ones.

The join *type* decides what happens to rows that find no match:

| Join type    | Keeps...                                                            |
|--------------|--------------------------------------------------------------------|
| `INNER JOIN` | only rows that match on both sides                                 |
| `LEFT JOIN`  | all left rows; right side is NULL when unmatched                   |
| `RIGHT JOIN` | all right rows; left side is NULL when unmatched                   |
| `FULL JOIN`  | all rows from both sides; NULLs fill the gaps                      |
| self join    | a table joined to itself (e.g. employees to their managers)        |

## Build & prove

**INNER JOIN — projects with their client and freelancer names:**
```sql
SELECT p.title, c.company_name AS client, f.full_name AS freelancer
FROM projects p
JOIN clients c     ON c.id = p.client_id
JOIN freelancers f ON f.id = p.freelancer_id
ORDER BY p.title;
```
Every project has a client and a freelancer (both are `NOT NULL` foreign keys), so inner join shows all 8.

**Count projects per freelancer (inner join + group):**
```sql
SELECT f.full_name, count(p.id) AS projects
FROM freelancers f
JOIN projects p ON p.freelancer_id = f.id
GROUP BY f.full_name
ORDER BY projects DESC, f.full_name;
```
Expected:
```
   full_name     | projects
-----------------+----------
 Aisha Patel     |        2
 Naledi Botha    |        2
 Thabo Nkosi     |        2
 Lerato Dlamini  |        1
 Sipho Mahlangu  |        1
```

**LEFT JOIN — the difference that matters.** Which freelancers have *no* invoices linked through their projects? Inner join would silently hide them; left join reveals them:
```sql
SELECT f.full_name, count(i.id) AS invoice_count
FROM freelancers f
LEFT JOIN projects p ON p.freelancer_id = f.id
LEFT JOIN invoices i ON i.project_id = p.id
GROUP BY f.full_name
ORDER BY invoice_count, f.full_name;
```
A freelancer whose projects were never invoiced shows `0` instead of vanishing. **This is the number-one real-world use of LEFT JOIN: finding the absence of something.**

**Finding orphans / gaps with `LEFT JOIN ... WHERE right IS NULL`:**
```sql
-- projects that have no invoice yet
SELECT p.title
FROM projects p
LEFT JOIN invoices i ON i.project_id = p.id
WHERE i.id IS NULL
ORDER BY p.title;
```
The `WHERE i.id IS NULL` keeps only the unmatched left rows — projects with no invoice.

**Self join — pair up freelancers who share the same availability** (illustrative):
```sql
SELECT a.full_name AS one, b.full_name AS another
FROM freelancers a
JOIN freelancers b
  ON a.is_available = b.is_available
 AND a.id < b.id            -- a.id < b.id avoids duplicate/mirror pairs and self-pairs
ORDER BY one, another;
```

## Break it (on purpose): the accidental cross join

Forget the `ON` clause (use a comma with no condition) and you get an explosion:
```sql
SELECT count(*) FROM freelancers, projects;   -- 5 * 8 = 40 rows, all meaningless
```
Expected: `40`. That's the unfiltered cross product. If a query returns *way* more rows than you expect, a missing/incorrect join condition is the usual culprit.

## Exercises

1. Show each client's company name alongside every project title they own (inner join).
2. List all clients and the number of projects each has — including any client with zero (LEFT JOIN + count).
3. Find every project that has a `quote` but no `invoice` yet.
4. For each invoice, show the client company, the project title, and the invoice status, sorted by status.
5. Cause a cross join by dropping the `ON`, observe the row count, then fix it.

Solution: `solutions/04.sql`.

## Checkpoint

You can connect tables with all join types and — crucially — use LEFT JOIN to find what's *missing*. Next: turning many rows into summary numbers.
