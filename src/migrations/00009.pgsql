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

CREATE FUNCTION internal.replace_transaction (
  IN old_transaction_id uuid,
  IN new_date DATE,
  IN new_text TEXT,
  IN rows internal.add_transaction_row[])
  RETURNS void
  LANGUAGE 'plpgsql'
AS $$
  DECLARE
    row internal.add_transaction_row;
  BEGIN
    IF (SELECT COUNT(*)
        FROM public.transaction
        WHERE id = old_transaction_id) <> 1 THEN
      RAISE EXCEPTION 'Transaction with the specified ID not found.';
    END IF;

    IF (SELECT COUNT(*) FROM
         (SELECT SUM(r.amount)
           AS commodity_amount
           FROM UNNEST(rows) r
           GROUP BY commodity)
        AS commodity_amount
      WHERE commodity_amount <> 0::DECIMAL(38,18)) <> 0 THEN
      RAISE EXCEPTION 'Sum of transaction row amounts are distinct from zero.';
    END IF;

    UPDATE internal.transaction t
    SET date = new_date,
        text = new_text
    WHERE id = old_transaction_id;

    DELETE FROM internal.transaction_row
    WHERE transaction_id = old_transaction_id;

    FOREACH row IN ARRAY rows LOOP
      INSERT INTO internal.transaction_row
        ("transaction_id", account_id, amount, commodity)
      VALUES (old_transaction_id, row.account_id, row.amount, row.commodity);
    END LOOP;
  END;
$$;

CREATE FUNCTION public.replace_transaction (
  IN transaction_id uuid,
  IN date DATE,
  IN text TEXT,
  VARIADIC rows public.add_transaction_row[])
  RETURNS void
  LANGUAGE 'sql'
AS $$
  SELECT internal.replace_transaction (transaction_id, date, text,
    internal.map_public_to_internal_transaction_row(rows));
$$;

COMMENT ON FUNCTION
public.replace_transaction(uuid, date, text, public.add_transaction_row[]) IS
'Replaces the transaction with the specified ID with a new transaction. The ID
and insertion order are carried over to the new transaction, while the rest
of the fields and the transaction''s rows are replaced by the arguments to this
function.';

CREATE FUNCTION public.replace_transaction_arrayrows (
  IN transaction_id uuid,
  IN date DATE,
  IN text TEXT,
  rows public.add_transaction_row[])
  RETURNS void
  LANGUAGE 'sql'
AS $$
  SELECT internal.replace_transaction (transaction_id, date, text,
    internal.map_public_to_internal_transaction_row(rows));
$$;

INSERT INTO internal.migrations (id) VALUES (9);
