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

CREATE TABLE internal.formula (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  name TEXT NOT NULL UNIQUE
);

COMMENT ON TABLE internal.formula IS
'Formulas are used to keep track of a set of accounts over time. An example is
to define a formula called Net Worth as Assets minus Liabilities (the formula
will include all subaccounts by default).';

CREATE VIEW public.formula AS
  SELECT id, name FROM internal.formula;

COMMENT ON VIEW public.formula IS
'Formulas are used to keep track of a set of accounts over time. An example is
to define a formula called Net Worth as Assets minus Liabilities (the formula
will include all subaccounts by default).';

CREATE FUNCTION public.add_formula (IN formula_name TEXT)
  RETURNS uuid
  LANGUAGE 'sql'
AS $$
  INSERT INTO internal.formula (name) VALUES (formula_name)
  RETURNING id;
$$;

COMMENT ON FUNCTION public.add_formula IS
'Adds a new (empty) formula with the specified name.';

CREATE TABLE internal.formula_term (
  formula_id uuid NOT NULL REFERENCES internal.formula ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES internal.account ON DELETE CASCADE,
  positive BOOLEAN NOT NULL,
  PRIMARY KEY (formula_id, account_id)
);

COMMENT ON TABLE internal.formula_term IS
'Contains the relationships between formulas and accounts. The positive flag
indicates whether the amount of the account should be added or subtracted
in the formula.';

CREATE VIEW public.formula_term AS
  SELECT ft.formula_id, a.full_name AS account_full_name, ft.positive
  FROM internal.formula_term ft
  JOIN internal.account_materialized_view a ON a.id = ft.account_id;
  
COMMENT ON VIEW public.formula_term IS
'Contains the relationships between formulas and accounts. The positive flag
indicates whether the amount of the account should be added or subtracted
in the formula.';

CREATE FUNCTION public.add_formula_term (
  IN formula_id uuid,
  IN account_full_name TEXT,
  IN positive BOOLEAN)
  RETURNS void
  LANGUAGE 'sql'
AS $$
  INSERT INTO internal.formula_term (formula_id, account_id, positive)
  VALUES (formula_id, internal.get_account_id(account_full_name), positive);
$$;

COMMENT ON FUNCTION public.add_formula_term IS
'Adds a new formula term for the specified formula.';

INSERT INTO internal.migrations (id) VALUES (6);
