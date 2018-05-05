DROP VIEW public.transaction_row;

CREATE VIEW public.transaction_row AS
  SELECT tr.id, tr.transaction_id, a.full_name as account_name, tr.amount, tr.commodity
  FROM internal.transaction_row tr
  JOIN internal.account_materialized_view a ON tr.account_id = a.id;
  
COMMENT ON VIEW public.transaction_row IS 'View for getting transaction rows.';

INSERT INTO internal.migrations (id) VALUES (2);
