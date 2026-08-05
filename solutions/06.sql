-- Module 06 solutions
-- 1 budget above avg for its status (correlated)
SELECT title, status, budget FROM projects p
WHERE budget > (SELECT avg(budget) FROM projects x WHERE x.status = p.status)
ORDER BY status, budget DESC;
-- 2 clients with no invoices
SELECT company_name FROM clients c
WHERE NOT EXISTS (
    SELECT 1 FROM projects p JOIN invoices i ON i.project_id=p.id WHERE p.client_id=c.id
) ORDER BY company_name;
-- 3 freelancers billed > 60000 via CTE
WITH billed AS (
    SELECT p.freelancer_id, sum(ii.quantity*ii.unit_price) AS total
    FROM projects p JOIN invoices i ON i.project_id=p.id JOIN invoice_items ii ON ii.invoice_id=i.id
    GROUP BY p.freelancer_id
)
SELECT f.full_name, round(b.total,2) AS billed
FROM billed b JOIN freelancers f ON f.id=b.freelancer_id
WHERE b.total > 60000 ORDER BY billed DESC;
-- 4 three equivalent phrasings
SELECT company_name FROM clients WHERE id IN (SELECT client_id FROM projects WHERE status='completed') ORDER BY company_name;
SELECT company_name FROM clients c WHERE EXISTS (SELECT 1 FROM projects p WHERE p.client_id=c.id AND p.status='completed') ORDER BY company_name;
SELECT DISTINCT c.company_name FROM clients c JOIN projects p ON p.client_id=c.id WHERE p.status='completed' ORDER BY c.company_name;
-- 5 the too-many-rows error, then fixed
-- SELECT title FROM projects WHERE budget = (SELECT budget FROM projects);  -- errors
SELECT title FROM projects WHERE budget = (SELECT max(budget) FROM projects);  -- fixed
