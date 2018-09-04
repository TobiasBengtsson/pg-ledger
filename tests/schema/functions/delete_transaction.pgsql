BEGIN;
SELECT plan(1);

SELECT has_function(
  'delete_transaction',
  ARRAY['uuid']);

SELECT * FROM finish();
ROLLBACK;
