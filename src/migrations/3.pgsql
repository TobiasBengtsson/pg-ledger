/*
  pg-ledger: A ledger-like accounting app for PostgreSQL
  Copyright (C) 2018  Tobias Bengtsson

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

CREATE FUNCTION public.account_balance_at_date(IN at_date DATE)
  RETURNS TABLE (
    account_name TEXT,
    commodity VARCHAR(20),
    balance DECIMAL(38,18)
  )
  LANGUAGE 'sql'
AS $$
  SELECT acc.full_name AS account_name,
         c.symbol AS commodity,
         SUM(tr.amount) AS balance
  FROM internal.transaction_row tr
  JOIN internal.transaction t
    ON tr.transaction_id = t.id
  JOIN internal.account_materialized_view acc
    ON tr.account_id = acc.id
  JOIN internal.commodity c
    ON tr.commodity = c.symbol
  WHERE t.date <= at_date
  GROUP BY acc.full_name, c.symbol
  HAVING SUM(tr.amount) <> 0;
$$;

COMMENT ON FUNCTION public.account_balance_at_date(date) IS
'Function that calculates the balances of accounts at (the end of) a particular
date.';

CREATE FUNCTION public.account_balance_change(IN from_date DATE, IN to_date DATE)
  RETURNS TABLE (
    account_name TEXT,
    commodity VARCHAR(20),
    starting_balance DECIMAL(38,18),
    ending_balance DECIMAL(38,18),
    balance_change DECIMAL(38,18)
  )
  LANGUAGE 'sql'
AS $$
  SELECT COALESCE(sb.account_name, eb.account_name),
         COALESCE(sb.commodity, eb.commodity),
         COALESCE(sb.balance, 0) AS starting_balance,
         COALESCE(eb.balance, 0) AS ending_balance,
         COALESCE(eb.balance, 0) - COALESCE(sb.balance, 0) AS balance_change
  FROM public.account_balance_at_date(from_date - 1) sb
  FULL OUTER JOIN public.account_balance_at_date(to_date) eb
    ON sb.account_name = eb.account_name AND sb.commodity = eb.commodity
$$;

COMMENT ON FUNCTION public.account_balance_change(date, date) IS
'Function that calculates the balance change between two dates. The starting
balance is equal to the balance at the end of the day before the from_date.';

CREATE FUNCTION public.account_balance_change_from(IN from_date DATE)
  RETURNS TABLE (
    account_name TEXT,
    commodity VARCHAR(20),
    starting_balance DECIMAL(38,18),
    ending_balance DECIMAL(38,18),
    balance_change DECIMAL(38,18)
  )
  LANGUAGE 'sql'
AS $$
  SELECT COALESCE(sb.account_name, eb.account_name),
         COALESCE(sb.commodity, eb.commodity),
         COALESCE(sb.balance, 0) AS starting_balance,
         COALESCE(eb.balance, 0) AS ending_balance,
         COALESCE(eb.balance, 0) - COALESCE(sb.balance, 0) AS balance_change
  FROM public.account_balance_at_date(from_date - 1) sb
  FULL OUTER JOIN public.account_balance eb
    ON sb.account_name = eb.account_name AND sb.commodity = eb.commodity
$$;

COMMENT ON FUNCTION public.account_balance_change_from(date) IS
'Function that calculates the balance change from a date. The from date
balance is equal to the balance at the end of the day before the from_date.';

INSERT INTO internal.migrations (id) VALUES (3);
