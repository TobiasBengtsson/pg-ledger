BEGIN;
SELECT plan(1);

SELECT has_function(
  'transactions_by_account',
  ARRAY['text']);

SELECT * FROM finish();
ROLLBACK;
