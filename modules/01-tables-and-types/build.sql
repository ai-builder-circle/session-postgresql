-- Module 01 — Tables & Data Types
-- Run with: make run FILE=modules/01-tables-and-types/build.sql

DROP TABLE IF EXISTS freelancers CASCADE;
DROP TABLE IF EXISTS clients CASCADE;

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

INSERT INTO freelancers (full_name, email, hourly_rate)
VALUES ('Thabo Nkosi', 'thabo@example.co.za', 650.00),
       ('Aisha Patel', 'aisha@example.co.za', 800.00);

INSERT INTO clients (company_name, contact_email)
VALUES ('Kagiso Media', 'ops@kagiso.example'),
       ('Brightwave Studio', 'hello@brightwave.example');

SELECT id, full_name, hourly_rate, is_available FROM freelancers;
