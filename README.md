# PostgreSQL By Building

Learn PostgreSQL by **building one real database from empty to production-shaped** — not by reading theory.

You are building **FreelanceForge**: a database for a platform where freelancers send quotes, turn them into invoices, and collect payments from clients. Every module adds a real piece. By Module 12 you have a solid, normalised, indexed, constrained database you actually understand — because you built every table yourself.

## The method

Each module follows the same loop:

1. **Mechanism** — a short, plain-language explanation of *what the thing actually does* under the hood (no hand-waving).
2. **Build** — you run real SQL that changes the real database.
3. **Runnable proof** — you run a query and see the exact output that proves it worked. If your output matches, you understood it.
4. **Break it** — you deliberately trigger the error so you know what the guardrail feels like.
5. **Exercises** — you do it yourself, unaided. Solutions are in `/solutions`.

Do them **in order**. Each module assumes the previous one ran.

## What you need

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (or Docker Engine + Compose). That's it. You do **not** need to install PostgreSQL locally.
- A terminal. On Windows, use PowerShell or WSL.

## Start here

```bash
make up        # starts PostgreSQL 16 in a container
make psql      # opens an interactive SQL shell
```

If `make` is not available on Windows, every command has a raw `docker` equivalent in `modules/00-setup/README.md`.

To type SQL yourself, use `make psql`. To run a whole file at once:

```bash
make run FILE=modules/01-tables-and-types/build.sql
```

Useful commands (run `make help` to see all):

| Command        | What it does                                        |
|----------------|-----------------------------------------------------|
| `make up`      | Start the database                                  |
| `make psql`    | Open interactive SQL shell                          |
| `make down`    | Stop the database (keeps your data)                 |
| `make destroy` | Stop and **wipe** all data (fresh start)            |
| `make reset`   | Rebuild the finished schema from scratch instantly  |
| `make status`  | Is it running?                                      |

## The modules

| #  | Module                        | What you build / learn                                   |
|----|-------------------------------|----------------------------------------------------------|
| 00 | Setup                         | Run Postgres, connect, survive `psql`                    |
| 01 | Tables & Types                | `clients` and `freelancers` tables, real data types      |
| 02 | Constraints                   | PK, FK, UNIQUE, CHECK, NOT NULL — the database's spine    |
| 03 | Querying                      | `SELECT`, `WHERE`, `ORDER BY`, pattern matching          |
| 04 | Joins                         | Connect the tables; inner/left/right/full/self joins     |
| 05 | Aggregations                  | `GROUP BY`, `HAVING`, revenue reporting                  |
| 06 | Subqueries & CTEs             | Compose queries; the `WITH` clause                       |
| 07 | Indexes & EXPLAIN             | *Why* queries are slow, and how to prove they got fast   |
| 08 | Transactions                  | ACID, `BEGIN/COMMIT/ROLLBACK`, isolation, money safety   |
| 09 | Views                         | Views & materialised views for reporting                 |
| 10 | Functions & Triggers          | Auto-update timestamps, enforce business rules in the DB |
| 11 | Window Functions              | Running totals, rankings, per-client analytics           |
| 12 | Capstone                      | Normalisation, the full schema, and a health-check       |

## If you get lost

Run `make reset` at any time. It rebuilds the entire finished database from `db/schema.sql` in one shot, so you can jump into any module with a correct starting point. To start over completely blank, run `make destroy && make up`.

## The data model you are building toward

```
freelancers ──< projects >── clients
                   │
                   ├──< quotes ──< quote_items
                   │
                   └──< invoices ──< invoice_items
                            │
                            └──< payments
```

`──<` means "one to many". One freelancer has many projects; one quote has many line items; one invoice has many payments. You'll build this from the leftmost table rightward.
