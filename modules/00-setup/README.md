# Module 00 — Setup & Survival

Goal: get PostgreSQL running, connect to it, and learn just enough `psql` to not feel lost.

## Mechanism: what is PostgreSQL, actually?

PostgreSQL is a **server program**. It runs in the background, listens on a network port (default `5432`), and waits for clients to send it SQL over that connection. It is *not* a file you open like a spreadsheet.

So there are always two halves:

- **The server** — the `postgres` process holding your data. We run it inside a Docker container so everyone's is identical.
- **A client** — a program that connects and sends SQL. We use `psql`, the official command-line client.

When you run `make psql`, you are launching a `psql` client *inside the container* and pointing it at the server, also in the container. They talk over a socket. That's the whole picture.

## Build: start the server

```bash
make up
```

Expected output ends with:

```
Ready. Run 'make psql' to connect.
```

Check it's alive:

```bash
make status
```

You should see a container `pbb_postgres` with status `Up ... (healthy)`.

## Runnable proof: connect and ask the server who it is

```bash
make psql
```

Your prompt changes to:

```
freelanceforge=#
```

That `=#` prompt means: *connected, and the server is waiting for SQL.* Now run:

```sql
SELECT version();
```

Expected (version string will match your machine, but shape is identical):

```
                                                version
---------------------------------------------------------------------------------------------------------
 PostgreSQL 16.x (Debian ...) on x86_64-pc-linux-gnu, compiled by gcc ...
(1 row)
```

You just sent SQL to a database server and got a real answer back. That's the entire game — everything else is just more interesting SQL.

## Survival kit: psql meta-commands

Commands starting with a backslash are **psql commands**, not SQL. They don't need a semicolon. The essential ones:

| Command      | What it does                                  |
|--------------|-----------------------------------------------|
| `\l`         | list all databases                            |
| `\c dbname`  | connect to a different database               |
| `\dt`        | list tables in the current database           |
| `\d tablename` | describe a table (columns, types, constraints) |
| `\dn`        | list schemas                                  |
| `\di`        | list indexes                                  |
| `\x`         | toggle "expanded" display (great for wide rows)|
| `\timing`    | toggle showing how long each query took       |
| `\?`         | help on psql commands                         |
| `\h SELECT`  | help on the SQL `SELECT` command              |
| `\q`         | quit                                          |

Try `\dt` now. Expected:

```
Did not find any relations.
```

Correct — the database is empty. You'll fix that in Module 01.

## Break it (on purpose)

SQL statements **must end with a semicolon**. Type this and press Enter:

```sql
SELECT 1
```

Nothing happens — the prompt becomes `freelanceforge-#`. The `-#` means "I'm still reading your statement, waiting for the semicolon." Type `;` and Enter, and it runs. This trips up every beginner once. Now it won't trip you.

Quit with `\q`.

## Raw docker commands (if `make` is unavailable, e.g. some Windows setups)

| make command   | raw equivalent                                                        |
|----------------|-----------------------------------------------------------------------|
| `make up`      | `docker compose up -d`                                                 |
| `make psql`    | `docker compose exec db psql -U forge -d freelanceforge`              |
| `make down`    | `docker compose down`                                                  |
| `make destroy` | `docker compose down -v`                                               |
| `make run FILE=x.sql` | `docker compose exec -T db psql -U forge -d freelanceforge -f /repo/x.sql` |

## Connecting from a GUI (optional)

If you prefer a GUI like DBeaver, TablePlus, or pgAdmin, connect with:

- Host: `localhost`
- Port: `5433`  ← note: 5433 on your machine, not 5432
- Database: `freelanceforge`
- User: `forge`
- Password: `forge`

## Checkpoint

You can start the server, connect, run a query, read `\dt`, and quit. On to building real tables.
