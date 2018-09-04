BEGIN;
SELECT plan(2);

SELECT has_view('transaction_row');

SELECT columns_are(
  'transaction_row',
  ARRAY['id', 'transaction_id', 'account_name', 'amount', 'commodity']
);

SELECT * FROM finish();
ROLLBACK;
