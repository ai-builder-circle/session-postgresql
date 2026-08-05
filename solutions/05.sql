-- Module 05 solutions
-- 1
SELECT status, round(avg(budget),2) AS avg_budget FROM projects GROUP BY status ORDER BY status;
-- 2
SELECT f.full_name, count(p.id) AS projects, coalesce(sum(p.budget),0) AS total_budget
FROM freelancers f LEFT JOIN projects p ON p.freelancer_id=f.id
GROUP BY f.full_name ORDER BY total_budget DESC;
-- 3
SELECT p.title, round(sum(ii.quantity*ii.unit_price),2) AS invoiced
FROM projects p JOIN invoices i ON i.project_id=p.id JOIN invoice_items ii ON ii.invoice_id=i.id
GROUP BY p.title ORDER BY invoiced DESC;
-- 4
SELECT f.full_name, count(p.id) AS n
FROM freelancers f JOIN projects p ON p.freelancer_id=f.id
GROUP BY f.full_name HAVING count(p.id) >= 2 ORDER BY n DESC;
-- 5 fix GROUP BY error
SELECT status, count(*), max(title) AS a_title FROM projects GROUP BY status;         -- wrap
SELECT status, title, count(*) FROM projects GROUP BY status, title;                  -- add to GROUP BY
