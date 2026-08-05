# Module 01 — Tables & Data Types

Goal: create your first real tables and understand *why* the right type matters.

## Mechanism: what a table really is

A table is a typed grid. Every **column** has a fixed **data type**, and PostgreSQL *enforces* it — you cannot sneak a word into a number column. This is the database's first and cheapest layer of protection: bad data is rejected at the door, before it can poison anything.

Choosing types well is not pedantry. The type decides:

- **What values are legal** (a `date` column can never hold "banana").
- **How much space it uses** and how fast comparisons are.
- **What operations you get** — you can do date-math on a `date`, but not on text that merely looks like a date.

## The types you'll actually use

| Type                       | Use it for                                    | Note                                             |
|----------------------------|-----------------------------------------------|--------------------------------------------------|
| `integer` / `int`          | whole numbers, counts                         | ±2.1 billion                                     |
| `bigint`                   | big whole numbers, IDs at scale               | huge range                                       |
| `numeric(p, s)`            | **money**, exact decimals                     | `numeric(12,2)` = 12 digits, 2 after the point   |
| `real` / `double precision`| scientific measurements                       | **never for money** — rounding errors            |
| `text`                     | strings of any length                         | prefer this over `varchar(n)` unless you need a hard cap |
| `varchar(n)`               | strings with a real max length                | e.g. a 2-letter country code                     |
| `boolean`                  | true/false                                    | accepts `true`, `false`, `'t'`, `'f'`            |
| `date`                     | a calendar day                                | `2026-08-05`                                      |
| `timestamptz`              | an exact moment, timezone-aware               | **prefer this** over plain `timestamp`           |
| `uuid`                     | globally-unique IDs                           | good for distributed / public-facing IDs         |

**Rule you must internalise:** money is always `numeric`. Using `real`/`float` for money means `0.1 + 0.2` might store as `0.30000000000000004`. Banks do not forgive that.

## Build: create the first two tables

Open the shell:

```bash
make psql
```

Then run the SQL below. (Or run it all at once with `make run FILE=modules/01-tables-and-types/build.sql`.)

```sql
CREATE TABLE freelancers (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     text        NOT NULL,
    email         text        NOT NULL,
    hourly_rate   numeric(10,2),
    is_available  boolean     NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE clients (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name  text        NOT NULL,
    contact_email text,
    country       varchar(2)  NOT NULL DEFAULT 'ZA',
    created_at    timestamptz NOT NULL DEFAULT now()
);
```

New pieces explained:

- **`GENERATED ALWAYS AS IDENTITY`** — Postgres auto-fills the `id` with the next number. You never set it yourself. This is the modern replacement for the old `serial`.
- **`PRIMARY KEY`** — this column uniquely identifies a row. More on this in Module 02.
- **`NOT NULL`** — this column may never be empty.
- **`DEFAULT now()`** — if you don't supply `created_at`, Postgres stamps the current moment.

## Runnable proof: put data in, read it back

```sql
INSERT INTO freelancers (full_name, email, hourly_rate)
VALUES ('Thabo Nkosi', 'thabo@example.co.za', 650.00),
       ('Aisha Patel', 'aisha@example.co.za', 800.00);

INSERT INTO clients (company_name, contact_email)
VALUES ('Kagiso Media', 'ops@kagiso.example'),
       ('Brightwave Studio', 'hello@brightwave.example');

SELECT id, full_name, hourly_rate, is_available, created_at
FROM freelancers;
```

Expected (your `created_at` timestamp will differ — that's fine):

```
 id |  full_name  | hourly_rate | is_available |          created_at
----+-------------+-------------+--------------+-------------------------------
  1 | Thabo Nkosi |      650.00 | t            | 2026-08-05 09:14:22.11+00
  2 | Aisha Patel |      800.00 | t            | 2026-08-05 09:14:22.11+00
(2 rows)
```

Notice: `id` was filled in automatically (1, 2). `is_available` defaulted to `t` (true). `created_at` got a timestamp for free. That's the schema doing work *for* you.

Now inspect the table structure itself:

```sql
\d freelancers
```

You'll see every column, its type, nullability, and the default. This is your X-ray view of any table.

## Break it (on purpose)

Try to insert nonsense into the typed columns:

```sql
INSERT INTO freelancers (full_name, email, hourly_rate)
VALUES ('Broken Person', 'x@example.com', 'not a number');
```

Expected error:

```
ERROR:  invalid input syntax for type numeric: "not a number"
```

That rejection *is the feature*. The type system caught the bad data. Now try omitting a required field:

```sql
INSERT INTO freelancers (email) VALUES ('noname@example.com');
```

Expected:

```
ERROR:  null value in column "full_name" of relation "freelancers" violates not-null constraint
```

`NOT NULL` did its job.

## Exercises

1. Create a `projects` table with: an identity `id` primary key, a `title` (`text`, required), a `budget` (money-safe type), a `status` (`text`, defaulting to `'draft'`), and a `created_at` (`timestamptz`, defaulting to now). Don't worry about linking it to other tables yet — that's Module 02.
2. Insert two projects.
3. Run `\d projects` and confirm every default and NOT-NULL is what you intended.
4. Deliberately try to insert a project with a `budget` of `'free'` and read the error.

Solution: `solutions/01.sql`.

## Checkpoint

You can create tables with correct types, insert rows, read them back, and you understand why money is `numeric` and IDs are `IDENTITY`. Next: making the database enforce your business rules.
