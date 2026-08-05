-- Module 08 solutions
-- 1 all-or-nothing insert of project + quote + items
BEGIN;
INSERT INTO projects (client_id, freelancer_id, title, budget, status)
VALUES (1,1,'Tx demo project',10000,'active');
INSERT INTO quotes (project_id) VALUES ((SELECT max(id) FROM projects));
INSERT INTO quote_items (quote_id, description, quantity, unit_price)
VALUES ((SELECT max(id) FROM quotes),'Item A',1,5000),
       ((SELECT max(id) FROM quotes),'Item B',2,2500);
COMMIT;
-- 2 rollback demo
BEGIN;
UPDATE projects SET status='cancelled' WHERE id=1;
SELECT status FROM projects WHERE id=1;   -- cancelled (inside tx)
ROLLBACK;
SELECT status FROM projects WHERE id=1;   -- original
-- 3 error -> aborted -> recover
BEGIN;
UPDATE projects SET status='active' WHERE id=2;
-- next line violates CHECK and aborts the tx:
-- INSERT INTO payments (invoice_id, amount) VALUES (1,-5);
ROLLBACK;
-- 4 savepoint
BEGIN;
INSERT INTO clients (company_name) VALUES ('Keep Me');
SAVEPOINT sp1;
INSERT INTO clients (company_name) VALUES ('Drop Me');
ROLLBACK TO sp1;
COMMIT;   -- only 'Keep Me' survived
DELETE FROM clients WHERE company_name='Keep Me';  -- cleanup
