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

-- PostgreSQL will automatically insert values corresponding to the default
-- order of the table (in this case the order of the transaction UUID:s).
-- This is acceptable in this case because if a migration has been made the
-- UUID:s should appear in the order they were inserted anyway.
ALTER TABLE internal.transaction
ADD COLUMN insertion_order BIGSERIAL UNIQUE;

DROP INDEX internal.transaction_date;
CREATE INDEX transaction_date_insertionorder ON internal.transaction (date, insertion_order);

CREATE OR REPLACE VIEW public.transaction AS
  SELECT id, date, text, insertion_order
  FROM internal.transaction;

INSERT INTO internal.migrations (id) VALUES (4);
