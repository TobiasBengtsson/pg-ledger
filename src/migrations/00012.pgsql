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

ALTER TABLE internal.transaction_row
DROP CONSTRAINT transaction_row_commodity_fkey,
ADD CONSTRAINT transaction_row_commodity_fkey
  FOREIGN KEY (commodity) REFERENCES internal.commodity (symbol)
  ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE FUNCTION public.edit_commodity(
  IN current_commodity_symbol VARCHAR(20),
  IN new_commodity_symbol VARCHAR(20),
  IN new_is_prefix BOOLEAN,
  IN new_has_space BOOLEAN
)
RETURNS void
LANGUAGE 'sql'
AS $$
  UPDATE internal.commodity
  SET symbol = new_commodity_symbol,
      is_prefix = new_is_prefix,
      has_space = new_has_space
  WHERE symbol = current_commodity_symbol;
$$;

COMMENT ON FUNCTION
public.edit_commodity(VARCHAR(20), VARCHAR(20), BOOLEAN, BOOLEAN)
IS
'Updates the commodity with the specified (current) symbol with new values for
symbol, is_prefix and has_space.';

CREATE FUNCTION public.edit_commodity(
  IN current_commodity_symbol VARCHAR(20),
  IN new_commodity_symbol VARCHAR(20)
)
RETURNS void
LANGUAGE 'sql'
AS $$
  UPDATE internal.commodity
  SET symbol = new_commodity_symbol
  WHERE symbol = current_commodity_symbol;
$$;

COMMENT ON FUNCTION public.edit_commodity(VARCHAR(20), VARCHAR(20)) IS
'Updates the symbol of the commodity with the specified current symbol.';

INSERT INTO internal.migrations (id) VALUES (12);
