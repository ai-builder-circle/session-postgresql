-- Module 10 solutions
-- 1
CREATE OR REPLACE FUNCTION project_billed(p_id bigint) RETURNS numeric AS $$
    SELECT round(coalesce(sum(ii.quantity*ii.unit_price),0),2)
    FROM invoices i JOIN invoice_items ii ON ii.invoice_id=i.id
    WHERE i.project_id=p_id;
$$ LANGUAGE sql;
SELECT project_billed(1);
-- 2 updated_at trigger on invoices
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_invoices_updated_at ON invoices;
CREATE TRIGGER trg_invoices_updated_at BEFORE UPDATE ON invoices
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
-- 3 reject payment over outstanding balance
CREATE OR REPLACE FUNCTION guard_overpay() RETURNS trigger AS $$
DECLARE billed numeric; collected numeric;
BEGIN
  SELECT coalesce(sum(quantity*unit_price),0) INTO billed FROM invoice_items WHERE invoice_id=NEW.invoice_id;
  SELECT coalesce(sum(amount),0) INTO collected FROM payments WHERE invoice_id=NEW.invoice_id;
  IF collected + NEW.amount > billed THEN
     RAISE EXCEPTION 'Payment % exceeds outstanding balance (billed %, already paid %)', NEW.amount, billed, collected;
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_guard_overpay ON payments;
CREATE TRIGGER trg_guard_overpay BEFORE INSERT ON payments
FOR EACH ROW EXECUTE FUNCTION guard_overpay();
-- 4 auto-mark paid when covered (AFTER INSERT, re-checks total, no recursion since we UPDATE invoices not payments)
CREATE OR REPLACE FUNCTION auto_mark_paid() RETURNS trigger AS $$
DECLARE billed numeric; collected numeric;
BEGIN
  SELECT coalesce(sum(quantity*unit_price),0) INTO billed FROM invoice_items WHERE invoice_id=NEW.invoice_id;
  SELECT coalesce(sum(amount),0) INTO collected FROM payments WHERE invoice_id=NEW.invoice_id;
  IF collected >= billed THEN
     UPDATE invoices SET status='paid' WHERE id=NEW.invoice_id AND status <> 'paid';
  END IF;
  RETURN NULL;  -- AFTER trigger: return value ignored
END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_auto_mark_paid ON payments;
CREATE TRIGGER trg_auto_mark_paid AFTER INSERT ON payments
FOR EACH ROW EXECUTE FUNCTION auto_mark_paid();
