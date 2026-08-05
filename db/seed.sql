-- ============================================================
-- Seed data for FreelanceForge.
-- Enough rows to make joins, aggregations and window functions interesting.
-- ============================================================

INSERT INTO freelancers (full_name, email, hourly_rate, is_available) VALUES
 ('Thabo Nkosi',      'thabo@example.co.za',   650.00, true),
 ('Aisha Patel',      'aisha@example.co.za',   800.00, true),
 ('Lerato Dlamini',   'lerato@example.co.za',  950.00, false),
 ('Sipho Mahlangu',   'sipho@example.co.za',   500.00, true),
 ('Naledi Botha',     'naledi@example.co.za', 1200.00, true);

INSERT INTO clients (company_name, contact_email, country) VALUES
 ('Kagiso Media',      'ops@kagiso.example',      'ZA'),
 ('Brightwave Studio', 'hello@brightwave.example','ZA'),
 ('Savanna Foods',     'admin@savanna.example',   'ZA'),
 ('Nordic Craft',      'team@nordic.example',     'SE'),
 ('Loop Fintech',      'billing@loop.example',    'ZA');

INSERT INTO projects (client_id, freelancer_id, title, budget, status) VALUES
 (1, 1, 'Podcast rebrand',        25000.00, 'completed'),
 (1, 2, 'Website redesign',       80000.00, 'active'),
 (2, 1, 'Brand identity kit',     45000.00, 'completed'),
 (3, 3, 'Packaging design',       60000.00, 'active'),
 (3, 4, 'Social media templates', 15000.00, 'completed'),
 (4, 5, 'Product launch site',   120000.00, 'active'),
 (5, 2, 'Onboarding flow UX',     55000.00, 'draft'),
 (5, 5, 'Investor deck design',   40000.00, 'completed');

-- Quotes (some accepted, some not) + their line items
INSERT INTO quotes (project_id, status, valid_until) VALUES
 (1, 'accepted', current_date + 10),
 (2, 'accepted', current_date + 20),
 (4, 'sent',     current_date + 15),
 (6, 'accepted', current_date + 25),
 (7, 'rejected', current_date - 5);

INSERT INTO quote_items (quote_id, description, quantity, unit_price) VALUES
 (1, 'Logo suite',          1, 15000.00),
 (1, 'Audio intro/outro',   2,  5000.00),
 (2, 'Design (pages)',     10,  4000.00),
 (2, 'Frontend build',     40,  1000.00),
 (3, 'Concept rounds',      3,  8000.00),
 (4, 'Full site design',    1, 70000.00),
 (4, 'Copywriting',        20,  1500.00),
 (5, 'UX audit',            1, 20000.00);

-- Invoices per project + line items
INSERT INTO invoices (project_id, status, issued_on, due_on) VALUES
 (1, 'paid',    current_date - 40, current_date - 26),
 (3, 'paid',    current_date - 30, current_date - 16),
 (5, 'paid',    current_date - 20, current_date - 6),
 (8, 'paid',    current_date - 15, current_date - 1),
 (2, 'unpaid',  current_date - 5,  current_date + 9),
 (4, 'overdue', current_date - 25, current_date - 11),
 (6, 'unpaid',  current_date - 2,  current_date + 12);

INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
 (1, 'Logo suite',        1, 15000.00),
 (1, 'Audio intro/outro', 2,  5000.00),
 (2, 'Brand identity',    1, 45000.00),
 (3, 'Templates pack',    1, 15000.00),
 (4, 'Investor deck',     1, 40000.00),
 (5, 'Design milestone 1',1, 30000.00),
 (5, 'Design milestone 2',1, 30000.00),
 (6, 'Packaging round 1', 1, 35000.00),
 (7, 'Launch site build', 1, 60000.00);

-- Payments (paid invoices are fully paid; one partial payment on the unpaid #5)
INSERT INTO payments (invoice_id, amount, method, paid_at) VALUES
 (1, 25000.00, 'eft',     now() - interval '25 days'),
 (2, 45000.00, 'payfast', now() - interval '15 days'),
 (3, 15000.00, 'card',    now() - interval '5 days'),
 (4, 40000.00, 'eft',     now() - interval '1 days'),
 (5, 20000.00, 'eft',     now() - interval '3 days');  -- partial: invoice 5 totals 60000
