BEGIN;
SELECT plan(1);

SELECT has_function(
  'account_balance_change',
  ARRAY['date', 'date']);

SELECT * FROM finish();
ROLLBACK;
