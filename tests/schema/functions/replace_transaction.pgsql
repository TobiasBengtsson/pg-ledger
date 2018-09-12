BEGIN;
SELECT plan(1);

SELECT has_function(
  'replace_transaction',
  ARRAY['uuid', 'date', 'text', 'add_transaction_row[]']);

SELECT * FROM finish();
ROLLBACK;
