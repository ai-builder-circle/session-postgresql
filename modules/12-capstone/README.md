# Module 12 — Capstone: normalisation & the whole database

Goal: understand *why* the schema is shaped the way it is (normalisation), assemble the full picture, and run a health-check that exercises everything you've learned.

> `make reset` first — this loads the complete finished schema you've been building toward.

## Mechanism: normalisation, in plain language

Normalisation is the discipline of **storing each fact exactly once**. When a fact is duplicated, the copies eventually disagree — that's an *anomaly*. The normal forms are just escalating rules for removing duplication.

**Why not one giant table?** Imagine a single `everything` table with client name, freelancer name, project, and each line item as a row. Then:
- The client's name is repeated on every one of their line items (update it in one place, miss another → **update anomaly**).
- You can't record a client who has no project yet — there's no row to put them in (**insertion anomaly**).
- Delete a client's last line item and you lose the client entirely (**deletion anomaly**).

Splitting into `clients`, `projects`, `invoices`, `invoice_items` — linked by foreign keys — stores each fact once and kills all three anomalies. That's what you built.

The practical rules of thumb (1NF → 3NF):

1. **1NF** — one value per cell, no repeating groups. (No "items" column stuffed with a comma-list; use an `invoice_items` table.)
2. **2NF** — every non-key column depends on the *whole* primary key, not part of it.
3. **3NF** — non-key columns depend on the key *only*, not on each other. (Don't store `client_name` in `projects`; store `client_id` and look the name up.)

A good default: **3NF**. Denormalise deliberately (e.g. a materialised view) only when you've measured a real performance need — never by accident.

## The finished model

```
freelancers ──< projects >── clients
                   │
                   ├──< quotes ──< quote_items
                   │
                   └──< invoices ──< invoice_items
                            │
                            └──< payments
```

Every `──<` is a foreign key. Every table stores one kind of fact. Run `\d` on each to see the constraints doing their job:
```sql
\d freelancers
\d projects
\d invoices
```

## The capstone report: exercise everything at once

This single query uses **CTEs (06)**, **joins (04)**, **aggregation (05)**, **COALESCE for LEFT JOIN NULLs (06)**, and window-style thinking. It's a full client-account statement — the kind of thing FreelanceForge would show on a dashboard:

```sql
WITH billed AS (
    SELECT i.project_id,
           round(sum(ii.quantity * ii.unit_price), 2) AS invoiced
    FROM invoices i
    JOIN invoice_items ii ON ii.invoice_id = i.id
    GROUP BY i.project_id
),
collected AS (
    SELECT i.project_id,
           sum(pay.amount) AS paid
    FROM invoices i
    JOIN payments pay ON pay.invoice_id = i.id
    GROUP BY i.project_id
)
SELECT c.company_name,
       count(DISTINCT p.id)                          AS projects,
       coalesce(sum(b.invoiced), 0)                  AS total_invoiced,
       coalesce(sum(col.paid), 0)                    AS total_collected,
       coalesce(sum(b.invoiced), 0)
         - coalesce(sum(col.paid), 0)                AS outstanding
FROM clients c
LEFT JOIN projects  p   ON p.client_id = c.id
LEFT JOIN billed    b   ON b.project_id = p.id
LEFT JOIN collected col ON col.project_id = p.id
GROUP BY c.company_name
ORDER BY outstanding DESC, c.company_name;
```
Read the result: each client, how many projects, how much they've been invoiced, how much they've paid, and what they still owe. If `outstanding` is positive, that client owes money. This one query is a genuine business report — and you now understand every clause in it.

## Data-integrity health checks

Because you built constraints, these "can this ever be wrong?" checks should all return **zero rows**. Run them to prove the database can't hold nonsense:

```sql
-- 1. Any invoice item pointing at a non-existent invoice? (FK makes this impossible)
SELECT * FROM invoice_items ii
LEFT JOIN invoices i ON i.id = ii.invoice_id
WHERE i.id IS NULL;

-- 2. Any payment exceeding its invoice's billed total? (a real business check)
SELECT p.invoice_id, sum(p.amount) AS paid,
       (SELECT round(sum(quantity*unit_price),2) FROM invoice_items WHERE invoice_id = p.invoice_id) AS billed
FROM payments p
GROUP BY p.invoice_id
HAVING sum(p.amount) > (SELECT sum(quantity*unit_price) FROM invoice_items WHERE invoice_id = p.invoice_id);

-- 3. Any project with a status outside the allowed set? (CHECK makes this impossible)
SELECT * FROM projects
WHERE status NOT IN ('draft','active','completed','cancelled');
```
Checks 1 and 3 *cannot* return rows — the FK and CHECK constraints forbid the bad state from ever existing. Check 2 is a business rule the schema doesn't enforce yet (over-payment), so it's a genuine monitoring query — and a hint for how you'd extend the trigger from Module 10.

## Final challenge: extend the schema yourself

Put everything together. Add a **`freelancer_skills`** capability to the model, properly normalised:

1. Create a `skills` table (`id`, `name` unique).
2. Create a `freelancer_skills` **junction table** linking `freelancers` and `skills` many-to-many (a composite primary key `(freelancer_id, skill_id)`, both foreign keys, both cascading on delete). This is how you model many-to-many relationships — a table in the middle.
3. Seed a few skills and assignments.
4. Write a query: for each skill, how many available freelancers have it, ranked.
5. Write a query using a window function: within each skill, rank those freelancers by `hourly_rate`.
6. Add an index you can justify with `EXPLAIN`, and wrap the seeding in a transaction.

Solution: `solutions/12.sql`.

## You're done

You built a real, normalised, constrained, indexed database from an empty container — and you understand every layer:

- **Types & constraints** stop bad data at the door.
- **Joins, aggregation, subqueries, CTEs, window functions** get exactly the answers you need out.
- **Indexes** make it fast, and you can *prove* it with `EXPLAIN`.
- **Transactions** keep it correct under failure.
- **Views, functions, triggers** package logic and automate rules the app can never skip.
- **Normalisation** is the reason the whole thing stays consistent as it grows.

That is a solid database. Now go model something of your own — start from the entities, give each its own table, link them with foreign keys, and let the constraints carry the weight.
