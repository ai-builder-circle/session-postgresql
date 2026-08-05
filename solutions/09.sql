-- Module 09 solutions
-- 1
CREATE OR REPLACE VIEW active_projects AS
SELECT p.title, c.company_name AS client, f.full_name AS freelancer
FROM projects p JOIN clients c ON c.id=p.client_id JOIN freelancers f ON f.id=p.freelancer_id
WHERE p.status='active';
SELECT * FROM active_projects ORDER BY title;
-- 2
CREATE OR REPLACE VIEW overdue_invoices AS
SELECT i.id AS invoice_id, p.title, c.company_name, (current_date - i.due_on) AS days_overdue
FROM invoices i JOIN projects p ON p.id=i.project_id JOIN clients c ON c.id=p.client_id
WHERE i.status='overdue';
SELECT * FROM overdue_invoices;
-- 3 (assumes invoice_balances view from the module)
-- SELECT * FROM invoice_balances WHERE outstanding > 0;
-- 4 materialised view of projects per freelancer
DROP MATERIALIZED VIEW IF EXISTS proj_per_freelancer;
CREATE MATERIALIZED VIEW proj_per_freelancer AS
SELECT f.full_name, count(p.id) AS n
FROM freelancers f LEFT JOIN projects p ON p.freelancer_id=f.id
GROUP BY f.full_name;
SELECT * FROM proj_per_freelancer ORDER BY n DESC;
INSERT INTO projects (client_id, freelancer_id, title, status) VALUES (1,1,'MV test','draft');
SELECT * FROM proj_per_freelancer ORDER BY n DESC;   -- unchanged
REFRESH MATERIALIZED VIEW proj_per_freelancer;
SELECT * FROM proj_per_freelancer ORDER BY n DESC;   -- now +1 for that freelancer
DELETE FROM projects WHERE title='MV test'; REFRESH MATERIALIZED VIEW proj_per_freelancer;
