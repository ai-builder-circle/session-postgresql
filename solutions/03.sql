-- Module 03 solutions
-- 1
SELECT title, budget FROM projects WHERE budget >= 50000 ORDER BY budget DESC;
-- 2
SELECT full_name FROM freelancers WHERE full_name ILIKE '%a%' ORDER BY full_name;
-- 3
SELECT title FROM projects ORDER BY created_at DESC LIMIT 3;
-- 4
SELECT id, status, due_on FROM invoices WHERE status IN ('unpaid','overdue') ORDER BY due_on;
-- 5 (fix the alias trap two ways)
SELECT full_name, hourly_rate*8 AS daily FROM freelancers WHERE hourly_rate*8 > 5000;      -- repeat expr
SELECT * FROM (SELECT full_name, hourly_rate*8 AS daily FROM freelancers) s WHERE daily>5000; -- subquery
