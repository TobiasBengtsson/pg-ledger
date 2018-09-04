BEGIN;
SELECT plan(1);

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

SELECT * FROM finish();
ROLLBACK;
