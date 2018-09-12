BEGIN;
SELECT plan(7);

SELECT add_account('Assets:Bank:Savings');
SELECT add_account('Assets:Bank:Current');
SELECT add_account('Liabilities:Bank:Mortgage');

SELECT results_eq(
  'SELECT name::text, full_name, parent_name
  FROM account
  ORDER BY full_name;',
  'SELECT * FROM (VALUES
    (''Assets'', ''Assets'', NULL::text),
    (''Bank'', ''Assets:Bank'', ''Assets''),
    (''Current'', ''Assets:Bank:Current'', ''Assets:Bank''),
    (''Savings'', ''Assets:Bank:Savings'', ''Assets:Bank''),
    (''Liabilities'', ''Liabilities'', NULL::text),
    (''Bank'', ''Liabilities:Bank'', ''Liabilities''),
    (''Mortgage'', ''Liabilities:Bank:Mortgage'', ''Liabilities:Bank'')
  ) AS t (name, full_name, parent_name)',
  'Accounts should be added correctly');

SELECT results_eq(
  'SELECT delete_account(''non:existing:account'')',
  ARRAY[false],
  'If account does not exist, delete_account should return false');

SELECT delete_account('Assets:Bank');

SELECT results_eq(
  'SELECT name::text, full_name, parent_name
  FROM account
  ORDER BY full_name;',
  'SELECT * FROM (VALUES
    (''Assets'', ''Assets'', NULL::text),
    (''Liabilities'', ''Liabilities'', NULL::text),
    (''Bank'', ''Liabilities:Bank'', ''Liabilities''),
    (''Mortgage'', ''Liabilities:Bank:Mortgage'', ''Liabilities:Bank'')
  ) AS t (name, full_name, parent_name)',
  'delete_account should delete sub-accounts.');

SELECT add_commodity('USD');
SELECT add_transaction(
  '2018-09-12',
  'TestTransaction',
  ROW('Assets', 1, 'USD'),
  ROW('Liabilities:Bank:Mortgage', -1, 'USD'));

SELECT throws_ok(
  'SELECT delete_account(''Liabilities:Bank:Mortgage'')',
  '23503',
  'update or delete on table "account" violates foreign key constraint "transaction_row_account_id_fkey" on table "transaction_row"',
  'delete_account should result in FK violation error if account is used by a transaction');

SELECT throws_ok(
  'SELECT delete_account(''Liabilities'')',
  '23503',
  'update or delete on table "account" violates foreign key constraint "transaction_row_account_id_fkey" on table "transaction_row"',
  'delete_account should result in FK violation error if sub-account is used by a transaction');

SELECT add_account('FormulaAccount');
SELECT add_formula_term(add_formula('Formula'), 'FormulaAccount', true);

SELECT results_eq(
  'SELECT delete_account(''FormulaAccount'')',
  ARRAY[true],
  'delete_account should delete account even if referenced by formula');

SELECT is_empty(
  'SELECT * FROM formula_term',
  'delete_account should cascade deletes to formula terms');

SELECT * FROM finish();
ROLLBACK;
