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

CREATE FUNCTION internal.replace_transactions_account(
  IN account_id_to_be_replaced uuid,
  IN account_id_to_replace_with uuid
)
RETURNS void
LANGUAGE 'plpgsql'
AS $$
  BEGIN
    IF (SELECT COUNT(*) FROM internal.account WHERE id = account_id_to_be_replaced) < 1 THEN
      RAISE EXCEPTION 'Account to be replaced was not found.';
    ELSIF (SELECT COUNT(*) FROM internal.account WHERE id = account_id_to_replace_with) < 1 THEN
      RAISE EXCEPTION 'Account to replace with was not found.';
    ELSE
      UPDATE internal.transaction_row
      SET account_id = account_id_to_replace_with
      WHERE account_id = account_id_to_be_replaced;
    END IF;
  END;
$$;

CREATE FUNCTION public.replace_transactions_account(
  IN account_to_be_replaced TEXT,
  IN account_to_replace_with TEXT
)
RETURNS void
LANGUAGE 'sql'
AS $$
  SELECT internal.replace_transactions_account(
    internal.get_account_id(account_to_be_replaced),
    internal.get_account_id(account_to_replace_with)
  )
$$;

COMMENT ON FUNCTION public.replace_transactions_account is
'Replaces all occurences of the specified (first) account in the transactions
table with the other (second) account.

If one of the accounts does not exist, an error is thrown.';

INSERT INTO internal.migrations (id) VALUES (14);
