# Module 10 — Functions & Triggers: logic that lives in the database

Goal: write reusable functions, and make the database *react automatically* to changes.

> `make reset` first.

## Mechanism: functions run code; triggers run functions on events

A **function** is named, reusable logic that takes inputs and returns a value or a table. You can write them in plain SQL or in **PL/pgSQL**, Postgres's procedural language (variables, `IF`, loops).

A **trigger** connects a function to a table event. You say "before every `UPDATE` on `invoices`, run this function," and Postgres does it automatically — no application code can forget to. Triggers are how you enforce rules and automations that must *always* happen: audit logs, auto-timestamps, derived columns, guardrails.

Trigger timing: `BEFORE` (can modify the row before it's written) or `AFTER` (react once it's written), on `INSERT` / `UPDATE` / `DELETE`. Inside the function, `NEW` is the incoming row and `OLD` is the previous row.

## Build & prove #1: a simple SQL function

A reusable "what's the total of this invoice?" function:
```sql
CREATE OR REPLACE FUNCTION invoice_total(inv_id bigint)
RETURNS numeric AS $$
    SELECT round(coalesce(sum(quantity * unit_price), 0), 2)
    FROM invoice_items
    WHERE invoice_id = inv_id;
$$ LANGUAGE sql;

SELECT invoice_total(1) AS total_for_invoice_1;   -- 25000.00
SELECT invoice_total(5) AS total_for_invoice_5;   -- 60000.00
```
`$$ ... $$` is just a way to quote the function body so you don't have to escape inner quotes.

## Build & prove #2: an auto-updating `updated_at` (the classic trigger)

Add a column, then a trigger that keeps it current on every update — automatically.
```sql
ALTER TABLE projects ADD COLUMN updated_at timestamptz NOT NULL DEFAULT now();

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();   -- stamp the row being written
    RETURN NEW;                -- BEFORE triggers must return the (possibly modified) row
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_projects_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();
```
Prove it fires:
```sql
SELECT id, updated_at FROM projects WHERE id = 1;    -- note the time
UPDATE projects SET status = 'completed' WHERE id = 1;
SELECT id, updated_at FROM projects WHERE id = 1;    -- updated_at jumped to now()
```
You changed `status`; the trigger silently refreshed `updated_at`. No app code involved. This exact pattern is used in almost every production Postgres schema.

## Build & prove #3: a trigger that enforces a business rule

Rule: you may never mark an invoice `paid` unless payments cover its total. Enforce it in the database so no code path can violate it:
```sql
CREATE OR REPLACE FUNCTION guard_invoice_paid()
RETURNS trigger AS $$
DECLARE
    billed numeric;
    collected numeric;
BEGIN
    IF NEW.status = 'paid' AND OLD.status <> 'paid' THEN
        SELECT coalesce(sum(quantity*unit_price),0) INTO billed
        FROM invoice_items WHERE invoice_id = NEW.id;

        SELECT coalesce(sum(amount),0) INTO collected
        FROM payments WHERE invoice_id = NEW.id;

        IF collected < billed THEN
            RAISE EXCEPTION 'Cannot mark invoice % paid: collected % < billed %',
                NEW.id, collected, billed;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_guard_invoice_paid
BEFORE UPDATE ON invoices
FOR EACH ROW
EXECUTE FUNCTION guard_invoice_paid();
```
Prove it blocks a premature "paid" (invoice 5 is billed 60 000 but only 20 000 collected in the seed):
```sql
UPDATE invoices SET status = 'paid' WHERE id = 5;
```
Expected:
```
ERROR:  Cannot mark invoice 5 paid: collected 20000.00 < billed 60000.0000
```
(The `billed` figure shows extra trailing zeros because multiplying two `numeric` values widens the decimal scale — harmless here. Wrap it in `round(..., 2)` if you want it tidy.)
Now fully pay it, and the same update succeeds:
```sql
INSERT INTO payments (invoice_id, amount) VALUES (5, 40000);  -- brings collected to 60000
UPDATE invoices SET status = 'paid' WHERE id = 5;             -- now allowed
SELECT status FROM invoices WHERE id = 5;                     -- 'paid'
```
A rule that *cannot* be bypassed, living next to the data. That's the superpower of triggers.

## Break it (on purpose): the trigger you can't drop the function under

```sql
DROP FUNCTION set_updated_at();
```
Expected:
```
ERROR:  cannot drop function set_updated_at() because other objects depend on it
DETAIL:  trigger trg_projects_updated_at on table projects depends on function set_updated_at()
```
Postgres protects the dependency. Drop the trigger first, or use `DROP FUNCTION ... CASCADE` (which also drops the trigger). This dependency tracking is a feature — it stops you from silently breaking automations.

## Exercises

1. Write a SQL function `project_billed(p_id bigint)` returning the total invoiced amount for a project (sum across its invoices' items).
2. Add an `updated_at` + trigger to the `invoices` table, mirroring the projects one.
3. Write a `BEFORE INSERT` trigger on `payments` that rejects a payment larger than the invoice's outstanding balance.
4. Write an `AFTER INSERT` trigger on `payments` that automatically sets the invoice to `'paid'` once payments cover the total. (Careful: guard against recursion / re-check the total.)

Solution: `solutions/10.sql`.

## Checkpoint

You can write functions in SQL and PL/pgSQL and attach triggers that enforce rules and automate updates the application can never skip. Next: analytics across rows without collapsing them.
