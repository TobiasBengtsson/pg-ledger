-- PostgreSQL will automatically insert values corresponding to the default
-- order of the table (in this case the order of the transaction UUID:s).
-- This is acceptable in this case because if a migration has been made the
-- UUID:s should appear in the order they were inserted anyway.
ALTER TABLE internal.transaction
ADD COLUMN insertion_order BIGSERIAL UNIQUE;

DROP INDEX internal.transaction_date;
CREATE INDEX transaction_date_insertionorder ON internal.transaction (date, insertion_order);

CREATE OR REPLACE VIEW public.transaction AS
  SELECT id, date, text, insertion_order
  FROM internal.transaction;

INSERT INTO internal.migrations (id) VALUES (4);
