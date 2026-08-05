-- Module 04 solutions
-- 1
SELECT c.company_name, p.title FROM clients c JOIN projects p ON p.client_id=c.id ORDER BY c.company_name;
-- 2
SELECT c.company_name, count(p.id) AS projects
FROM clients c LEFT JOIN projects p ON p.client_id=c.id
GROUP BY c.company_name ORDER BY projects DESC, c.company_name;
-- 3 projects with a quote but no invoice
SELECT DISTINCT p.title
FROM projects p
JOIN quotes q ON q.project_id=p.id
LEFT JOIN invoices i ON i.project_id=p.id
WHERE i.id IS NULL ORDER BY p.title;
-- 4
SELECT i.id, c.company_name, p.title, i.status
FROM invoices i JOIN projects p ON p.id=i.project_id JOIN clients c ON c.id=p.client_id
ORDER BY i.status;
-- 5 cross join then fix
SELECT count(*) FROM freelancers, projects;                       -- explosion
SELECT count(*) FROM freelancers f JOIN projects p ON p.freelancer_id=f.id;  -- fixed
