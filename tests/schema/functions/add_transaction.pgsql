BEGIN;
SELECT plan(1);

SELECT has_function(
  'add_transaction',
  ARRAY['date', 'text', 'add_transaction_row[]']);

SELECT * FROM finish();
ROLLBACK;
