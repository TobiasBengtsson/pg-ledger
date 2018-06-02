CREATE FUNCTION internal.get_transaction_date_series()
  RETURNS TABLE (
    date DATE
  )
  LANGUAGE 'sql'
  STABLE
AS $$
  SELECT i::DATE
  FROM generate_series (
    (SELECT MIN(date) FROM internal.transaction),
    (SELECT MAX(date) FROM internal.transaction),
    '1 day'::interval) i;
$$;

COMMENT ON FUNCTION internal.get_transaction_date_series IS
'Gets a series of consecutive dates from the first registred transaction to
the latest.';

CREATE FUNCTION public.account_balance_at_date_recursive(IN at_date DATE)
  RETURNS TABLE (
    account_name TEXT,
    commodity VARCHAR(20),
    balance DECIMAL(38,18)
  )
  LANGUAGE 'sql'
  STABLE
AS $$
  SELECT acc.full_name AS account_name,
         c.symbol AS commodity,
         SUM(tr.amount) AS balance
  FROM public.transaction_row tr
  JOIN public.transaction t
    ON tr.transaction_id = t.id
  JOIN public.account acc
    ON tr.account_name LIKE acc.full_name || '%'
  JOIN internal.commodity c
    ON tr.commodity = c.symbol
  WHERE t.date <= at_date
  GROUP BY acc.full_name, c.symbol
  HAVING SUM(tr.amount) <> 0;
$$;

COMMENT ON FUNCTION public.account_balance_at_date_recursive(date) IS
'Function that calculates the balances of accounts at (the end of) a particular
date. In contrast to account_balance_at_date, this function includes all sub-
accounts.';

CREATE VIEW public.formula_history AS
  SELECT f.id, ts.date, c.symbol, SUM(ab.balance) FROM public.formula f
  JOIN public.formula_term ft ON ft.formula_id = f.id
  CROSS JOIN internal.get_transaction_date_series() ts
  CROSS JOIN internal.commodity c
  LEFT JOIN public.account_balance_at_date_recursive(ts.date) ab ON (ab.commodity = c.symbol AND ab.account_name = ft.account_full_name)
  WHERE ab.balance IS NOT NULL
  GROUP BY f.id, ts.date, c.symbol;

COMMENT ON VIEW public.formula_history IS
'Gets the day-to-day development of formulas in every commodity. The first date
is equal to the date of the first transaction in the system, similarly the last
day is equal to the date of the latest transaction in the system.';

INSERT INTO internal.migrations (id) VALUES (8);
