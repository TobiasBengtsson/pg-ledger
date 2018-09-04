BEGIN;
SELECT plan(1);

SELECT has_function(
  'account_balance_change_from',
  ARRAY['date']);

SELECT * FROM finish();
ROLLBACK;
