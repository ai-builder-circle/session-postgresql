# Module 02 — Constraints: the database's spine

Goal: make it *impossible* to store invalid or inconsistent data.

## Mechanism: rules the database enforces for you

Application code has bugs. People run manual `UPDATE`s at 2am. Two services write at once. If your only protection is "the app promises to be careful," your data *will* rot. Constraints move the rules into the database itself, where nothing can bypass them.

Five constraints do almost all the work:

| Constraint    | Guarantees                                             |
|---------------|--------------------------------------------------------|
| `NOT NULL`    | the value is always present                            |
| `UNIQUE`      | no two rows share this value                           |
| `PRIMARY KEY` | `UNIQUE` + `NOT NULL` — the row's identity             |
| `FOREIGN KEY` | this value must exist in another table (referential integrity) |
| `CHECK`       | the value satisfies a condition you write              |

The **foreign key** is the important one. It's what turns a pile of separate tables into a connected model. It says: "a project's `client_id` must point to a client that actually exists." The database will refuse to create an orphan, and refuse to delete a client that still has projects (unless you tell it what to do instead).

## Build: rebuild the tables with a full set of constraints, then link them

First rebuild `freelancers` and `clients` with the guarantees they were missing (a unique email, sane values):

```sql
-- run modules/01 first if these tables don't exist
ALTER TABLE freelancers ADD CONSTRAINT freelancers_email_unique UNIQUE (email);
ALTER TABLE freelancers ADD CONSTRAINT freelancers_rate_positive CHECK (hourly_rate > 0);
ALTER TABLE clients      ADD CONSTRAINT clients_email_unique UNIQUE (contact_email);
```

Now create `projects` **linked** to both tables with foreign keys:

```sql
CREATE TABLE projects (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id     bigint NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
    freelancer_id bigint NOT NULL REFERENCES freelancers(id) ON DELETE RESTRICT,
    title         text   NOT NULL,
    budget        numeric(12,2) CHECK (budget >= 0),
    status        text   NOT NULL DEFAULT 'draft'
                         CHECK (status IN ('draft','active','completed','cancelled')),
    created_at    timestamptz NOT NULL DEFAULT now()
);
```

Read that `projects` table slowly — it contains four different constraint ideas working together:

- **`REFERENCES clients(id)`** — foreign key. `client_id` must match a real client.
- **`ON DELETE RESTRICT`** — you may not delete a client who still has projects. (Alternatives: `CASCADE` deletes the projects too; `SET NULL` blanks the link.)
- **`CHECK (budget >= 0)`** — no negative budgets.
- **`CHECK (status IN (...))`** — a poor-man's enum. `status` can only be one of four words.

## Runnable proof: the links are enforced

Insert a valid project (client 1, freelancer 1 exist from Module 01):

```sql
INSERT INTO projects (client_id, freelancer_id, title, budget, status)
VALUES (1, 1, 'Podcast rebrand', 25000.00, 'active');

SELECT p.id, c.company_name, f.full_name, p.title, p.status
FROM projects p
JOIN clients c     ON c.id = p.client_id
JOIN freelancers f ON f.id = p.freelancer_id;
```

Expected:

```
 id | company_name | full_name   |     title       | status
----+--------------+-------------+-----------------+--------
  1 | Kagiso Media | Thabo Nkosi | Podcast rebrand | active
(1 row)
```

(That `JOIN` is Module 04 — for now just enjoy that the link works.)

## Break it (four ways — do all of them)

**1. Orphan foreign key** — point at a client that doesn't exist:

```sql
INSERT INTO projects (client_id, freelancer_id, title)
VALUES (999, 1, 'Ghost project');
```
```
ERROR:  insert or update on table "projects" violates foreign key constraint ...
DETAIL:  Key (client_id)=(999) is not present in table "clients".
```

**2. Illegal status** — the CHECK rejects it:

```sql
INSERT INTO projects (client_id, freelancer_id, title, status)
VALUES (1, 1, 'Bad status', 'in_progress');
```
```
ERROR:  new row for relation "projects" violates check constraint "projects_status_check"
```

**3. Duplicate email** — the UNIQUE rejects it:

```sql
INSERT INTO freelancers (full_name, email, hourly_rate)
VALUES ('Impostor', 'thabo@example.co.za', 500);
```
```
ERROR:  duplicate key value violates unique constraint "freelancers_email_unique"
```

**4. Delete a client who has projects** — RESTRICT blocks it:

```sql
DELETE FROM clients WHERE id = 1;
```
```
ERROR:  update or delete on table "clients" violates foreign key constraint ... on table "projects"
```

Four different disasters, four automatic refusals. You didn't write a line of application code for any of them.

## Exercises

1. Add a `CHECK` to `clients` ensuring `country` is exactly 2 uppercase letters. Hint: `CHECK (country ~ '^[A-Z]{2}$')` (that `~` is a regex match).
2. Create an `invoices` table with an identity PK, a `project_id` foreign key to `projects` (use `ON DELETE CASCADE` this time — deleting a project should delete its invoices), an `amount numeric(12,2)` that must be `> 0`, a `status` restricted to `('unpaid','paid','overdue')` defaulting to `'unpaid'`, and an `issued_on date NOT NULL DEFAULT current_date`.
3. Prove your CASCADE works: insert a project + an invoice, delete the project, then confirm the invoice is gone too.
4. Explain in one sentence (in a comment) why you'd choose `RESTRICT` for `projects.client_id` but `CASCADE` for `invoices.project_id`.

Solution: `solutions/02.sql`.

## Checkpoint

Your database now refuses invalid, orphaned, duplicate, and inconsistent data on its own. This is the single biggest step from "storing data" to "trusting data." Next: getting data back out precisely.
