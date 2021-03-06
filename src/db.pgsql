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

CREATE EXTENSION "uuid-ossp";

CREATE SCHEMA internal;
COMMENT ON SCHEMA internal IS
'Schema for features that should not be exposed to users of the database.';

COMMENT ON SCHEMA public
  IS 'Schema for public features of the database.';

CREATE TABLE internal.account (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  name VARCHAR(100) NOT NULL CHECK (LENGTH(name) > 0),
  parent_id uuid REFERENCES internal.account ON DELETE CASCADE
);

COMMENT ON TABLE internal.account IS
'Contains all accounts used in the database.

The accounts are structured in a tree-like fashion, using a recursive nullable
parent foreign key to the same table. There is also a constraint that two
siblings must have unique name (so there can be for example only one
Assets:Bank:HSBC account, but it is still possible to have
Liabilities:Loans:HSBC in the same database).';

CREATE UNIQUE INDEX top_level_account_unique
ON internal.account (LOWER(name))
WHERE parent_id IS NULL;

CREATE UNIQUE INDEX sub_level_account_unique
ON internal.account (LOWER(name), parent_id)
WHERE parent_id IS NOT NULL;

CREATE FUNCTION internal.add_account(
  IN name TEXT,
  IN parent_id uuid)
  RETURNS uuid
  LANGUAGE 'sql'
AS $$
  INSERT INTO internal.account ("name", "parent_id")
  VALUES (TRIM(name), parent_id)
  RETURNING id;
$$;

COMMENT ON FUNCTION internal.add_account(text, uuid) IS 'Adds a sub-level
account to the database (i.e. the account has a parent). Returns the UUID
of the newly created account.';

CREATE FUNCTION internal.add_account(IN name TEXT) RETURNS uuid
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_account(name, NULL);
$$;

COMMENT ON FUNCTION internal.add_account(text) IS
'Adds a top-level account to the database. Returns the UUID of the newly
created account.';

CREATE FUNCTION public.add_account(IN full_name TEXT) RETURNS TEXT
  LANGUAGE 'plpgsql'
AS $$
  DECLARE
    current_account_id uuid;
    current_account_name TEXT;
    current_account_level INT;
    current_parent_id uuid;
  BEGIN
    current_account_level := 1;
    current_parent_id = NULL;
    LOOP
      current_account_name := split_part(
        full_name,
        ':',
        current_account_level);

      EXIT WHEN LENGTH(TRIM(current_account_name)) < 1;

      SELECT id FROM internal.account
      WHERE name = current_account_name
        AND ((current_parent_id IS NULL AND parent_id IS NULL)
        OR parent_id = current_parent_id)
      LIMIT 1 INTO current_account_id;

      IF current_account_id IS NULL THEN
        current_parent_id := internal.add_account(
          current_account_name,
          current_parent_id);
      ELSE
        current_parent_id := current_account_id;
      END IF;
      current_account_level := current_account_level + 1;
    END LOOP;

    RETURN (
      SELECT amv.full_name
      FROM internal.account_materialized_view amv
      WHERE id = current_parent_id);
  END;
$$;

COMMENT ON FUNCTION public.add_account(text) IS
'Adds a new account to the database on the format
Topaccount:Subaccount:Subsubaccount and so on. Will check if necessary parent
accounts exists and also create them if needed.

Example: If adding Assets:Bank:Citibank, and if Assets exists but not
Assets:Bank, the function will first create Assets:Bank which has Assets as a
parent account. Then it will create Assets:Bank:Citibank with the newly created
Assets:Bank account as parent account.

Whitespace will be trimmed from the start and the end of accounts (and
consequently also whitespace around ":" characters).

Multiple accounts with the same name and parent (or same name if top-level
account) are not allowed. The matching is case insensitive, so Assets and
ASSETS are not both allowed as top-level accounts. However the casing used
when adding an account the first time will be saved.';

CREATE RECURSIVE VIEW internal.account_view(
  id, name, parent_id, parent_name, full_name) AS
  SELECT id, name, parent_id, NULL AS parent_name,
         CAST (name AS TEXT) AS full_name
  FROM internal.account
  WHERE parent_id IS NULL
  UNION ALL
    SELECT ia.id, ia.name, ia.parent_id, pa.full_name,
           pa.full_name || ':' || ia.name
    FROM account_view pa, internal.account ia
    WHERE pa.id = ia.parent_id;

COMMENT ON VIEW internal.account_view IS
'Internal view to be able to more simply perform operations on the recursive
account structure. In most cases, `internal.account_materialized_view` should
be used, which is a materialization of this view for performance gains.';

CREATE MATERIALIZED VIEW internal.account_materialized_view(
  id, name, parent_id, parent_name, full_name) AS
  SELECT id, name, parent_id, parent_name, full_name
  FROM internal.account_view;

COMMENT ON MATERIALIZED VIEW internal.account_materialized_view IS
'Materializes `internal.account_view`. This view should always be used for
reads of account information internally for performance reasons.';

CREATE FUNCTION internal.trigger_refresh_account_materialized_view()
  RETURNS trigger
  LANGUAGE 'plpgsql'
AS $$
  BEGIN
    REFRESH MATERIALIZED VIEW internal.account_materialized_view;
    RETURN NULL;
  END;
$$;

COMMENT ON FUNCTION internal.trigger_refresh_account_materialized_view() IS
'Trigger that updates `internal.account_materialized_view`. Meant to be run
on every update to the `internal.account` table.';

CREATE TRIGGER trigger_refresh_account_materialized_view
AFTER INSERT OR UPDATE OR DELETE
ON internal.account
FOR EACH STATEMENT EXECUTE PROCEDURE
internal.trigger_refresh_account_materialized_view();

COMMENT ON TRIGGER trigger_refresh_account_materialized_view
ON internal.account IS
'Trigger that calls the `internal.trigger_refresh_account_materialized_view`
function on updates to the `internal`.`account` table.';

CREATE VIEW public.account(full_name, parent_name, name) AS
  SELECT full_name, parent_name, name FROM internal.account_materialized_view;

COMMENT ON VIEW public.account IS 'View for accounts.';

CREATE TABLE internal.commodity (
  symbol VARCHAR(20) PRIMARY KEY,
  is_prefix BOOLEAN NOT NULL,
  has_space BOOLEAN NOT NULL
);

COMMENT ON TABLE internal.commodity IS
'Commodities and currencies are treated in the same manner. `is_prefix`
determines whether the commodity should be printed before or after the amount,
while `has_space` controls if there should be a space between the amount and
the commodity in print.';

CREATE VIEW public.commodity AS
  SELECT symbol, is_prefix, has_space FROM internal.commodity;

COMMENT ON VIEW public.commodity IS
'Commodities and currencies are treated in the same manner. `is_prefix`
determines whether the commodity should be printed before or after the amount,
while `has_space` controls if there should be aspace between the amount and the
commodity in print.';

CREATE FUNCTION internal.add_commodity(
  IN symbol VARCHAR(20),
  IN is_prefix BOOLEAN,
  IN has_space BOOLEAN)
  RETURNS VARCHAR(20)
  LANGUAGE 'plpgsql'
AS $$
  DECLARE
    trimmed_symbol VARCHAR(20);
  BEGIN
    trimmed_symbol := TRIM(symbol);
    IF trimmed_symbol LIKE '% %' THEN
      RAISE EXCEPTION 'Symbol with internal whitespace: %', trimmed_symbol;
    ELSE
      INSERT INTO internal.commodity ("symbol", "is_prefix", "has_space")
      VALUES (trimmed_symbol, is_prefix, has_space);
      RETURN trimmed_symbol;
    END IF;
  END;
$$;

COMMENT ON FUNCTION internal.add_commodity(VARCHAR(20), BOOLEAN, BOOLEAN) IS
'Adds a new commodity with custom settings.';

CREATE FUNCTION public.add_commodity(IN symbol VARCHAR(20)) RETURNS VARCHAR(20)
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_commodity (symbol, FALSE, TRUE);
$$;

COMMENT ON FUNCTION public.add_commodity(VARCHAR(20)) IS
'Adds a new commodity with default settings (will look like "1.23 ABC").';

CREATE FUNCTION public.add_commodity(
  IN symbol VARCHAR(20),
  IN is_prefix BOOLEAN,
  IN has_space BOOLEAN)
  RETURNS VARCHAR(20)
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_commodity (symbol, is_prefix, has_space);
$$;

COMMENT ON FUNCTION public.add_commodity(VARCHAR(20), BOOLEAN, BOOLEAN) IS
'Adds a new commodity with custom settings.';

CREATE TABLE internal.transaction (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  date date NOT NULL,
  text TEXT NOT NULL,
  insertion_order BIGSERIAL UNIQUE
);

COMMENT ON TABLE internal.transaction IS
'Table for storing transactions.The rows of the transaction are stored in
`internal.transaction_row`';

CREATE INDEX transaction_date_insertionorder ON internal.transaction (date, insertion_order);

CREATE TABLE internal.transaction_row (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  transaction_id uuid NOT NULL
    REFERENCES internal.transaction ON DELETE CASCADE,
  account_id uuid NOT NULL
    REFERENCES internal.account ON DELETE RESTRICT,
  amount DECIMAL(38,18) NOT NULL,
  commodity VARCHAR(20) NOT NULL
    REFERENCES internal.commodity ON UPDATE CASCADE ON DELETE RESTRICT
);

COMMENT ON TABLE internal.transaction_row IS
'Table for storing rows of transactions (from table `internal.transaction`).';

CREATE INDEX transaction_row_transaction_id
ON internal.transaction_row (transaction_id);

CREATE INDEX transaction_row_account_id
ON internal.transaction_row (account_id);

CREATE TYPE internal.add_transaction_row AS (
  account_id uuid,
  amount DECIMAL(38,18),
  commodity VARCHAR(20)
);

CREATE FUNCTION internal.add_transaction (
  IN date DATE,
  IN text TEXT,
  IN rows internal.add_transaction_row[])
  RETURNS uuid
  LANGUAGE 'plpgsql'
AS $$
  DECLARE
    transaction_id uuid;
    row internal.add_transaction_row;
  BEGIN
    IF (SELECT COUNT(*) FROM
         (SELECT SUM(r.amount)
           AS commodity_amount
           FROM UNNEST(rows) r
           GROUP BY commodity)
        AS commodity_amount
      WHERE commodity_amount <> 0::DECIMAL(38,18)) <> 0 THEN
      RAISE EXCEPTION 'Sum of transaction row amounts are distinct from zero.';
    END IF;

    INSERT INTO internal.transaction ("date", "text")
    VALUES (date, text) RETURNING id INTO transaction_id;

    FOREACH row IN ARRAY rows LOOP
      INSERT INTO internal.transaction_row
        ("transaction_id", account_id, amount, commodity)
      VALUES (transaction_id, row.account_id, row.amount, row.commodity);
    END LOOP;

    RETURN transaction_id;
  END;
$$;

COMMENT ON FUNCTION
internal.add_transaction(date, text, internal.add_transaction_row[]) IS
'Entry point for adding a new transaction.';

CREATE FUNCTION internal.get_account_id(IN account_full_name TEXT) RETURNS uuid
  LANGUAGE 'sql'
AS $$
  SELECT id
  FROM internal.account_materialized_view
  WHERE full_name = account_full_name;
$$;

COMMENT ON FUNCTION internal.get_account_id(text) IS
'Get the account id from the account full name (e.g. Assets:Bank:Citibank).
Will trim any whitespace at the start and end of string, as well as around the
account separation character ":".';

CREATE INDEX account_full_name_id_lookup
ON internal.account_materialized_view (full_name, id);

CREATE TYPE public.add_transaction_row AS (
  account_full_name TEXT,
  amount DECIMAL(38,18),
  commodity VARCHAR(20)
);

CREATE FUNCTION internal.map_public_to_internal_transaction_row(
  IN public_rows public.add_transaction_row[])
  RETURNS internal.add_transaction_row[]
  LANGUAGE 'sql'
AS $$
  SELECT ARRAY(
    SELECT (internal.get_account_id(account_full_name),
            amount,
            commodity)::internal.add_transaction_row
    FROM UNNEST(public_rows));
$$;

COMMENT ON FUNCTION
internal.map_public_to_internal_transaction_row(public.add_transaction_row[])
IS 'Converts an array of public.add_transaction to an array of
internal.add_transaction, by replacing full names of accounts with their
corresponding internal IDs.';

CREATE FUNCTION public.add_transaction_arrayrows (IN date DATE, IN text TEXT,
  rows public.add_transaction_row[])
  RETURNS uuid
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_transaction (date, text,
    internal.map_public_to_internal_transaction_row(rows));
$$;

CREATE FUNCTION public.add_transaction (IN date DATE, IN text TEXT,
  VARIADIC rows public.add_transaction_row[])
  RETURNS uuid
  LANGUAGE 'sql'
AS $$
  SELECT internal.add_transaction (date, text,
    internal.map_public_to_internal_transaction_row(rows));
$$;

CREATE VIEW public.account_balance AS
  SELECT acc.full_name AS account_name,
         c.symbol AS commodity,
         SUM(tr.amount) AS balance
  FROM internal.transaction_row tr
  JOIN internal.account_materialized_view acc
    ON tr.account_id = acc.id
  JOIN internal.commodity c
    ON tr.commodity = c.symbol
  GROUP BY acc.full_name, c.symbol
  HAVING SUM(tr.amount) <> 0;

COMMENT ON VIEW public.account_balance IS
'View for getting the current balances of accounts.';

CREATE VIEW public.transaction AS
  SELECT id, date, text, insertion_order
  FROM internal.transaction;

COMMENT ON VIEW public.transaction IS 'View for getting transactions.';

CREATE VIEW public.transaction_row AS
  SELECT tr.id, tr.transaction_id, a.full_name as account_name, tr.amount, tr.commodity
  FROM internal.transaction_row tr
  JOIN internal.account_materialized_view a ON tr.account_id = a.id;

COMMENT ON VIEW public.transaction_row IS 'View for getting transaction rows.';

CREATE FUNCTION public.delete_transaction (IN transaction_id uuid)
  RETURNS BOOLEAN
  LANGUAGE 'sql'
AS $$
  WITH del AS
    (DELETE FROM internal.transaction WHERE id = transaction_id RETURNING *)
  SELECT COUNT(*) > 0 AS deleted FROM del;
$$;

COMMENT ON FUNCTION public.delete_transaction(uuid) IS
'Deletes the transaction with the specified ID (will also delete the
corresponding transaction rows).

Returns a boolean indicating whether a row was deleted or not.';

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

CREATE TABLE internal.migrations (
  id int PRIMARY KEY
);

INSERT INTO internal.migrations (id) VALUES (1);
INSERT INTO internal.migrations (id) VALUES (2);

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
INSERT INTO internal.migrations (id) VALUES (4);

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
INSERT INTO internal.migrations (id) VALUES (7);

CREATE FUNCTION internal.get_transaction_date_series()
  RETURNS TABLE (
    date DATE
  )
  LANGUAGE 'sql'
  STABLE
AS $$
  SELECT i::DATE
  FROM generate_series (
    (SELECT MIN(date) FROM internal.transaction),
    (SELECT MAX(date) FROM internal.transaction),
    '1 day'::interval) i;
$$;

COMMENT ON FUNCTION internal.get_transaction_date_series IS
'Gets a series of consecutive dates from the first registred transaction to
the latest.';

CREATE FUNCTION public.account_balance_at_date_recursive(IN at_date DATE)
  RETURNS TABLE (
    account_name TEXT,
    commodity VARCHAR(20),
    balance DECIMAL(38,18)
  )
  LANGUAGE 'sql'
  STABLE
AS $$
  SELECT acc.full_name AS account_name,
         c.symbol AS commodity,
         SUM(tr.amount) AS balance
  FROM public.transaction_row tr
  JOIN public.transaction t
    ON tr.transaction_id = t.id
  JOIN public.account acc
    ON tr.account_name LIKE acc.full_name || '%'
  JOIN internal.commodity c
    ON tr.commodity = c.symbol
  WHERE t.date <= at_date
  GROUP BY acc.full_name, c.symbol
  HAVING SUM(tr.amount) <> 0;
$$;

COMMENT ON FUNCTION public.account_balance_at_date_recursive(date) IS
'Function that calculates the balances of accounts at (the end of) a particular
date. In contrast to account_balance_at_date, this function includes all sub-
accounts.';

CREATE VIEW public.formula_history AS
  SELECT f.id, ts.date, c.symbol, SUM(ab.balance) FROM public.formula f
  JOIN public.formula_term ft ON ft.formula_id = f.id
  CROSS JOIN internal.get_transaction_date_series() ts
  CROSS JOIN internal.commodity c
  LEFT JOIN public.account_balance_at_date_recursive(ts.date) ab ON (ab.commodity = c.symbol AND ab.account_name = ft.account_full_name)
  WHERE ab.balance IS NOT NULL
  GROUP BY f.id, ts.date, c.symbol;

COMMENT ON VIEW public.formula_history IS
'Gets the day-to-day development of formulas in every commodity. The first date
is equal to the date of the first transaction in the system, similarly the last
day is equal to the date of the latest transaction in the system.';

INSERT INTO internal.migrations (id) VALUES (8);
INSERT INTO internal.migrations (id) VALUES (9);

CREATE FUNCTION public.delete_account (IN account_full_name TEXT)
  RETURNS BOOLEAN
  LANGUAGE 'sql'
AS $$
  WITH del AS
    (DELETE FROM internal.account
      WHERE id = internal.get_account_id(account_full_name)
      RETURNING *)
  SELECT COUNT(*) > 0 AS deleted FROM del;
$$;

COMMENT ON FUNCTION public.delete_account(text) IS
'Deletes the account with the specified full name. Note that if the account is
in use, there are certain FK relationships that prevents the account from being
deleted.

Deleting a parent account will cause all its sub-accounts to be deleted as well
(provided they are not in use).

Returns a boolean indicating whether an account was deleted.';

INSERT INTO internal.migrations (id) VALUES (10);

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
