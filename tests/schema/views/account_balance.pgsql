BEGIN;
SELECT plan(2);

SELECT has_view('account_balance');

SELECT columns_are(
  'account_balance',
  ARRAY['account_name','commodity','balance' ]
);

SELECT * FROM finish();
ROLLBACK;
