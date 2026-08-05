-- Module 02 — Constraints
-- Assumes Module 01 tables exist. Run modules/01 first if needed.

ALTER TABLE freelancers ADD CONSTRAINT freelancers_email_unique UNIQUE (email);
ALTER TABLE freelancers ADD CONSTRAINT freelancers_rate_positive CHECK (hourly_rate > 0);
ALTER TABLE clients      ADD CONSTRAINT clients_email_unique UNIQUE (contact_email);

DROP TABLE IF EXISTS projects CASCADE;

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

INSERT INTO projects (client_id, freelancer_id, title, budget, status)
VALUES (1, 1, 'Podcast rebrand', 25000.00, 'active');

SELECT p.id, c.company_name, f.full_name, p.title, p.status
FROM projects p
JOIN clients c     ON c.id = p.client_id
JOIN freelancers f ON f.id = p.freelancer_id;
