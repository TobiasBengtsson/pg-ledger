BEGIN;
SELECT plan(1);

SELECT has_function(
  'account_balance_at_date',
  ARRAY['date']);

SELECT * FROM finish();
ROLLBACK;
