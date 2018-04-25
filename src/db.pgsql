CREATE USER pgledger_superuser PASSWORD 'CHANGE_ME';
CREATE USER pgledger_user PASSWORD 'CHANGE_ME';

CREATE DATABASE pgledger WITH OWNER=pgledger_superuser;

COMMENT ON DATABASE pgledger
  IS 'Ledger-like database for accounting';

CREATE EXTENSION "uuid-ossp";

CREATE SCHEMA internal AUTHORIZATION pgledger_superuser;
COMMENT ON SCHEMA internal IS 'Schema for features that should not be exposed to users of the database.';

ALTER SCHEMA public OWNER TO pgledger_superuser;
GRANT ALL ON SCHEMA public TO pgledger_user;
COMMENT ON SCHEMA public
  IS 'Schema for public features of the database.';

CREATE TABLE internal.account (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  name VARCHAR(100) NOT NULL,
  parent_id uuid REFERENCES internal.account,
  UNIQUE(name, parent_id)
);

COMMENT ON TABLE internal.account IS 'Contains all accounts used in the database. The accounts are structured in a tree-like fashion, using a recursive nullable parent foreign key to the same table. There is also a constraint that two siblings must have unique name (so there can be for example only one Assets:Bank:HSBC account, but it is still possible to have Liabilities:Loans:HSBC in the same database).';

CREATE FUNCTION internal.add_account(IN name TEXT) RETURNS uuid
  LANGUAGE 'sql'
AS $$
    INSERT INTO internal.account ("name", "parent_id") VALUES (name, NULL)
    RETURNING id;
$$;

COMMENT ON FUNCTION internal.add_account(text) IS 'Adds a top-level account to the database. Returns the UUID of the newly created account.';

CREATE FUNCTION internal.add_account(IN name TEXT, IN parent_id uuid) RETURNS uuid
  LANGUAGE 'sql'
AS $$
  INSERT INTO internal.account ("name", "parent_id") VALUES (name, parent_id)
  RETURNING id;
$$;

COMMENT ON FUNCTION internal.add_account(text, uuid) IS 'Adds a sub-level account to the database (i.e. the account has a parent). Returns the UUID of the newly created account.';

CREATE RECURSIVE VIEW internal.account_view(id, name, parent_id, parent_name, full_name) AS
  SELECT id, name, parent_id, NULL AS parent_name, CAST (name AS TEXT) AS full_name
  FROM internal.account
  WHERE parent_id IS NULL
  UNION ALL
    SELECT ia.id, ia.name, ia.parent_id, pa.full_name, pa.full_name || ':' || ia.name
    FROM account_view pa, internal.account ia
    WHERE pa.id = ia.parent_id;

COMMENT ON VIEW internal.account_view IS 'Internal view to be able to more simply perform operations on the recursive account structure. In most cases, `internal.account_materialized_view` should be used, which is a materialization of this view for performance gains.';

CREATE MATERIALIZED VIEW internal.account_materialized_view(id, name, parent_id, parent_name, full_name) AS
  SELECT id, name, parent_id, parent_name, full_name FROM internal.account_view;

COMMENT ON MATERIALIZED VIEW internal.account_materialized_view IS 'Materializes `internal.account_view`. This view should always be used for reads of account information internally for performance reasons.';

CREATE FUNCTION internal.trigger_refresh_account_materialized_view() RETURNS trigger
  LANGUAGE 'plpgsql'
AS $$
  BEGIN
    REFRESH MATERIALIZED VIEW internal.account_materialized_view;
    RETURN NULL;
  END;
$$;

COMMENT ON FUNCTION internal.trigger_refresh_account_materialized_view IS 'Trigger that updates `internal.account_materialized_view`. Meant to be run on every update to the `internal.account` table.';

CREATE TRIGGER trigger_refresh_account_materialized_view AFTER INSERT OR UPDATE OR DELETE
ON internal.account
FOR EACH STATEMENT EXECUTE PROCEDURE internal.trigger_refresh_account_materialized_view();

COMMENT ON TRIGGER trigger_refresh_account_materialized_view ON internal.account IS 'Trigger that calls the `internal.trigger_refresh_account_materialized_view` function on updates to the `internal`.`account` table.';

CREATE VIEW public.account(full_name, parent_name, name) AS
  SELECT full_name, parent_name, name FROM internal.account_materialized_view;

COMMENT ON VIEW public.account IS 'View for accounts.';
