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

DROP VIEW public.transaction_row;

CREATE VIEW public.transaction_row AS
  SELECT tr.id, tr.transaction_id, a.full_name as account_name, tr.amount, tr.commodity
  FROM internal.transaction_row tr
  JOIN internal.account_materialized_view a ON tr.account_id = a.id;
  
COMMENT ON VIEW public.transaction_row IS 'View for getting transaction rows.';

INSERT INTO internal.migrations (id) VALUES (2);
