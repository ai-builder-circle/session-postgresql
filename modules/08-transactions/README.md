# Module 08 — Transactions: keeping data correct when things go wrong

Goal: group operations so they succeed or fail *as one unit*. This is what makes a database safe for money.

> `make reset` first.

## Mechanism: ACID and the all-or-nothing guarantee

Suppose recording a payment means two steps: insert a `payments` row, and mark the invoice `paid`. If the power dies between them, you've taken money but the invoice still says unpaid — corruption. A **transaction** wraps both steps so that either **both** happen or **neither** does.

`BEGIN` opens a transaction; `COMMIT` makes all its changes permanent and visible to everyone; `ROLLBACK` throws them all away as if they never happened.

The guarantees are **ACID**:

- **Atomicity** — all-or-nothing. No half-finished states.
- **Consistency** — constraints hold at commit; a transaction can't leave the DB invalid.
- **Isolation** — concurrent transactions don't see each other's half-done work.
- **Durability** — once committed, it survives a crash.

## Build & prove: rollback undoes everything

In `psql`:
```sql
BEGIN;

INSERT INTO payments (invoice_id, amount, method)
VALUES (5, 40000.00, 'eft');

UPDATE invoices SET status = 'paid' WHERE id = 5;

-- look at your changes *inside* the transaction
SELECT status FROM invoices WHERE id = 5;   -- shows 'paid'

ROLLBACK;

-- now check again, outside the transaction
SELECT status FROM invoices WHERE id = 5;   -- back to 'unpaid'
```
The `ROLLBACK` erased both the insert and the update together. Nothing leaked out. Confirm the payment vanished too:
```sql
SELECT count(*) FROM payments WHERE invoice_id = 5 AND amount = 40000;  -- 0
```

Now do it for real with `COMMIT`:
```sql
BEGIN;
INSERT INTO payments (invoice_id, amount, method) VALUES (5, 40000.00, 'eft');
UPDATE invoices SET status = 'paid' WHERE id = 5;
COMMIT;

SELECT status FROM invoices WHERE id = 5;    -- 'paid', permanently
```

## Automatic rollback on error

If *any* statement in a transaction fails, Postgres aborts the whole thing — you must `ROLLBACK`:
```sql
BEGIN;
UPDATE invoices SET status = 'paid' WHERE id = 2;
INSERT INTO payments (invoice_id, amount) VALUES (2, -999);  -- violates CHECK (amount > 0)
```
The insert errors, and the session enters an aborted state:
```
ERROR:  new row for relation "payments" violates check constraint "payments_amount_check"
-- every further command now says:
ERROR:  current transaction is aborted, commands ignored until end of transaction block
```
Type `ROLLBACK;` to recover. The `UPDATE` to invoice 2 is discarded — exactly what you want. A partial write never survives.

## Savepoints: partial rollback

Sometimes you want to undo *part* of a transaction without abandoning all of it:
```sql
BEGIN;
INSERT INTO clients (company_name) VALUES ('Test A');
SAVEPOINT sp1;
INSERT INTO clients (company_name) VALUES ('Test B');
ROLLBACK TO sp1;    -- undoes 'Test B' only
COMMIT;             -- 'Test A' is kept
```

## Isolation, briefly (why it matters)

By default Postgres uses **Read Committed** isolation: each statement sees only data committed *before that statement began*. So a transaction never sees another transaction's uncommitted work (no "dirty reads"). For workflows where you read a value, decide, then write based on it (like decrementing stock), you may need a stricter level (`REPEATABLE READ` or `SERIALIZABLE`) or explicit row locks (`SELECT ... FOR UPDATE`) to avoid two sessions racing. You don't need to master this now — just know the default protects you from the worst cases, and stricter levels exist for the rest.

## Break it (on purpose): forgetting the transaction

Run these as two *separate* statements (no `BEGIN`):
```sql
UPDATE invoices SET status = 'paid' WHERE id = 6;
INSERT INTO payments (invoice_id, amount) VALUES (6, -100);   -- fails
```
The `UPDATE` already committed on its own. Now invoice 6 says `paid` but **no payment was recorded** — precisely the corruption transactions exist to prevent. Fix the data, and internalise the rule: *multi-step changes that must agree always go in a transaction.*
```sql
UPDATE invoices SET status = 'unpaid' WHERE id = 6;  -- repair
```

## Exercises

1. Write a single transaction that inserts a new project, a quote for it, and two quote items — committing only if all succeed.
2. Start a transaction, make a change, run a query to see it, then `ROLLBACK` and prove the change is gone.
3. Deliberately trigger a constraint error mid-transaction, observe the "aborted" state, and recover with `ROLLBACK`.
4. Use a `SAVEPOINT` to keep one insert while discarding a later one.

Solution: `solutions/08.sql`.

## Checkpoint

You can group operations atomically, roll back on error, use savepoints, and you understand why isolation matters. Your data can now survive failures without corrupting. Next: saving useful queries as reusable objects.
