-- Module 11 solutions
-- 1 running total of invoice totals by issued_on
WITH t AS (
  SELECT i.id, i.issued_on, round(sum(ii.quantity*ii.unit_price),2) AS total
  FROM invoices i JOIN invoice_items ii ON ii.invoice_id=i.id
  GROUP BY i.id, i.issued_on
)
SELECT id, issued_on, total,
       sum(total) OVER (ORDER BY issued_on, id) AS running_total
FROM t ORDER BY issued_on, id;
-- 2 clients ranked by lifetime revenue (all visible)
SELECT c.company_name,
       coalesce(sum(pay.amount),0) AS revenue,
       dense_rank() OVER (ORDER BY coalesce(sum(pay.amount),0) DESC) AS rnk
FROM clients c
LEFT JOIN projects p ON p.client_id=c.id
LEFT JOIN invoices i ON i.project_id=p.id
LEFT JOIN payments pay ON pay.invoice_id=i.id
GROUP BY c.company_name ORDER BY rnk;
-- 3 number each freelancer's projects by creation order
SELECT f.full_name, p.title,
       row_number() OVER (PARTITION BY f.id ORDER BY p.created_at) AS project_no
FROM freelancers f JOIN projects p ON p.freelancer_id=f.id
ORDER BY f.full_name, project_no;
-- 4 lag: budget diff from previous project per client
SELECT c.company_name, p.title, p.budget,
       p.budget - lag(p.budget) OVER (PARTITION BY c.id ORDER BY p.created_at) AS change
FROM clients c JOIN projects p ON p.client_id=c.id
ORDER BY c.company_name, p.created_at;
-- 5 most expensive project per client
SELECT company_name, title, budget FROM (
  SELECT c.company_name, p.title, p.budget,
         row_number() OVER (PARTITION BY c.id ORDER BY p.budget DESC NULLS LAST) AS rn
  FROM clients c JOIN projects p ON p.client_id=c.id
) s WHERE rn=1 ORDER BY company_name;
