-- ============================================================
-- FreelanceForge — the complete, finished schema.
-- This is the target you build toward across all 12 modules.
-- `make reset` runs db/reset.sql which loads this + the seed.
-- ============================================================

DROP TABLE IF EXISTS payments      CASCADE;
DROP TABLE IF EXISTS invoice_items CASCADE;
DROP TABLE IF EXISTS invoices      CASCADE;
DROP TABLE IF EXISTS quote_items   CASCADE;
DROP TABLE IF EXISTS quotes        CASCADE;
DROP TABLE IF EXISTS projects      CASCADE;
DROP TABLE IF EXISTS clients       CASCADE;
DROP TABLE IF EXISTS freelancers   CASCADE;

CREATE TABLE freelancers (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     text        NOT NULL,
    email         text        NOT NULL UNIQUE,
    hourly_rate   numeric(10,2) CHECK (hourly_rate > 0),
    is_available  boolean     NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE clients (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name  text        NOT NULL,
    contact_email text        UNIQUE,
    country       varchar(2)  NOT NULL DEFAULT 'ZA' CHECK (country ~ '^[A-Z]{2}$'),
    created_at    timestamptz NOT NULL DEFAULT now()
);

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

CREATE TABLE quotes (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id    bigint NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    status        text   NOT NULL DEFAULT 'sent'
                         CHECK (status IN ('sent','accepted','rejected','expired')),
    valid_until   date   NOT NULL DEFAULT (current_date + 30),
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE quote_items (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quote_id      bigint NOT NULL REFERENCES quotes(id) ON DELETE CASCADE,
    description   text   NOT NULL,
    quantity      numeric(10,2) NOT NULL CHECK (quantity > 0),
    unit_price    numeric(12,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE invoices (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id    bigint NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    status        text   NOT NULL DEFAULT 'unpaid'
                         CHECK (status IN ('unpaid','paid','overdue','cancelled')),
    issued_on     date   NOT NULL DEFAULT current_date,
    due_on        date   NOT NULL DEFAULT (current_date + 14),
    created_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (due_on >= issued_on)
);

CREATE TABLE invoice_items (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id    bigint NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description   text   NOT NULL,
    quantity      numeric(10,2) NOT NULL CHECK (quantity > 0),
    unit_price    numeric(12,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE payments (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_id    bigint NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    amount        numeric(12,2) NOT NULL CHECK (amount > 0),
    method        text   NOT NULL DEFAULT 'eft'
                         CHECK (method IN ('eft','card','cash','payfast')),
    paid_at       timestamptz NOT NULL DEFAULT now()
);

-- A couple of indexes we justify properly in Module 07.
CREATE INDEX idx_projects_client      ON projects(client_id);
CREATE INDEX idx_projects_freelancer  ON projects(freelancer_id);
CREATE INDEX idx_invoices_project     ON invoices(project_id);
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX idx_payments_invoice     ON payments(invoice_id);
