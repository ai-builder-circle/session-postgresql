-- Module 02 solutions
-- 1. country must be two uppercase letters
ALTER TABLE clients ADD CONSTRAINT clients_country_format CHECK (country ~ '^[A-Z]{2}$');

-- 2. invoices table with cascade
DROP TABLE IF EXISTS invoices CASCADE;
CREATE TABLE invoices (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    project_id bigint NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    amount     numeric(12,2) CHECK (amount > 0),
    status     text NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid','paid','overdue')),
    issued_on  date NOT NULL DEFAULT current_date
);

-- 3. prove cascade
INSERT INTO projects (client_id, freelancer_id, title) VALUES (1,1,'Cascade test');
INSERT INTO invoices (project_id, amount) VALUES ((SELECT max(id) FROM projects), 1000);
DELETE FROM projects WHERE title='Cascade test';           -- invoice goes too
SELECT count(*) AS should_be_zero FROM invoices WHERE amount=1000;

-- 4. RESTRICT vs CASCADE:
-- Deleting a client should be blocked if projects exist (RESTRICT) to avoid losing history,
-- but an invoice has no meaning without its project, so it should die with it (CASCADE).
