BEGIN;
SELECT plan(2);

SELECT add_account('Assets:Bank:Savings');
SELECT add_account('Assets:Bank:Current');
SELECT add_account('Liabilities:Bank:Mortgage');

SELECT add_commodity('USD');

SELECT add_transaction(
  '2018-09-04',
  'TestTransaction',
  ROW('Assets:Bank:Savings', 40.0, 'USD'),
  ROW('Assets:Bank:Current', 60.0, 'USD'),
  ROW('Liabilities:Bank:Mortgage', -100.0, 'USD'));

SELECT results_eq(
  'SELECT date, text, insertion_order::int
  FROM transaction;',
  'SELECT * FROM (VALUES
    (''2018-09-04''::date, ''TestTransaction'', 1)
  ) AS t (date, text, insertion_order)',
  'Transactions should be added correctly');

SELECT results_eq(
  'SELECT account_name, amount, commodity::text
  FROM transaction_row
  ORDER BY account_name;',
  'SELECT * FROM (VALUES
    (''Assets:Bank:Current'', 60.0, ''USD''),
    (''Assets:Bank:Savings'', 40.0, ''USD''),
    (''Liabilities:Bank:Mortgage'', -100.0, ''USD'')
  ) AS t (account_name, amount, commodity)',
  'Transaction rows should be added correctly');

SELECT * FROM finish();
ROLLBACK;
