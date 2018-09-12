BEGIN;
SELECT plan(1);

SELECT has_function(
  'delete_account',
  ARRAY['text']);

SELECT * FROM finish();
ROLLBACK;
