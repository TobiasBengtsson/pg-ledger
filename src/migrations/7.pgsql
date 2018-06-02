CREATE FUNCTION public.add_transaction_arrayrows (IN date DATE, IN text TEXT,
  rows public.add_transaction_row[])
  RETURNS uuid
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_transaction (date, text,
    internal.map_public_to_internal_transaction_row(rows));
$$;

INSERT INTO internal.migrations (id) VALUES (7);
