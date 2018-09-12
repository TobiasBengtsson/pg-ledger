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

CREATE FUNCTION public.transactions_by_account(IN account_full_name TEXT)
  RETURNS TABLE (
    transaction_id uuid,
    date date,
    text TEXT,
    insertion_order BIGINT,
    commodity VARCHAR(20),
    account_amount DECIMAL(38,18)
  )
  LANGUAGE 'sql'
AS $$
  SELECT t.id, t.date, t.text, t.insertion_order, tr.commodity, tr.account_amount
  FROM (SELECT transaction_id, SUM(amount) AS account_amount, commodity
  FROM public.transaction_row
  WHERE account_name = account_full_name
  GROUP BY transaction_id, commodity) tr
  JOIN public.transaction t ON t.id = tr.transaction_id
$$;

COMMENT ON FUNCTION public.transactions_by_account(TEXT) IS
'Get all transactions that contains at least one transaction row for the
account with the specified name. If the transaction contains multiple rows
with the same account and commodity, the amounts for that account and commodity
are summed in one row. If on the other hand a transaction contains multiple
rows with the same account but different commodities, they are presented as two
separate rows.';

INSERT INTO internal.migrations (id) VALUES (5);
