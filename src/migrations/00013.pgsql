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

CREATE FUNCTION internal.rename_account(
  IN account_id uuid,
  IN new_name VARCHAR(100)
)
RETURNS void
LANGUAGE 'plpgsql'
AS $$
  BEGIN
    IF new_name LIKE '%:%' THEN
      RAISE EXCEPTION 'New name cannot contain colons.';
    ELSIF (SELECT COUNT(*) FROM internal.account WHERE id = account_id) < 1 THEN
      RAISE EXCEPTION 'Account to rename was not found.';
    ELSE
      UPDATE internal.account
        SET name = new_name
        WHERE id = account_id;
    END IF;
  END
$$;

CREATE FUNCTION public.rename_account(
  IN account_full_name TEXT,
  IN new_name VARCHAR(100)
)
RETURNS void
LANGUAGE 'sql'
AS $$
  SELECT internal.rename_account(
    internal.get_account_id(account_full_name),
    new_name);
$$;

INSERT INTO internal.migrations (id) VALUES (13);
