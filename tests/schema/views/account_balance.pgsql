BEGIN;
SELECT plan(5);

SELECT has_view('account_balance');

SELECT columns_are(
  'account_balance',
  ARRAY['account_name','commodity','balance' ]
);

SELECT col_type_is(
  'account_balance',
  'account_name',
  'text');

SELECT col_type_is(
  'account_balance',
  'commodity',
  'character varying(20)');

SELECT col_type_is(
  'account_balance',
  'balance',
  'numeric');

SELECT * FROM finish();
ROLLBACK;
