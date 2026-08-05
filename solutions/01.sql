-- Module 01 solutions
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      text NOT NULL,
    budget     numeric(12,2),
    status     text NOT NULL DEFAULT 'draft',
    created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO projects (title, budget) VALUES ('Podcast rebrand', 25000), ('Website redesign', 80000);
-- \d projects   (run in psql to inspect)
-- This will error (budget is numeric):
-- INSERT INTO projects (title, budget) VALUES ('Bad', 'free');
