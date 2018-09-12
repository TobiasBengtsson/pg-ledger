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

CREATE FUNCTION public.delete_commodity (IN commodity_symbol VARCHAR(20))
  RETURNS BOOLEAN
  LANGUAGE 'sql'
AS $$
  WITH del AS
    (DELETE FROM internal.commodity
      WHERE symbol = commodity_symbol
      RETURNING *)
  SELECT COUNT(*) > 0 AS deleted FROM del;
$$;

COMMENT ON FUNCTION public.delete_commodity(VARCHAR(20)) IS
'Deletes the commodity with the specified symbol. Note that if the commodity is
in use, there are certain FK relationships that prevents the commodity from
being deleted.

Returns a boolean indicating whether a commodity was deleted.';

INSERT INTO internal.migrations (id) VALUES (11);
