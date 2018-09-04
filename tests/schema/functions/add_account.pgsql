BEGIN;
SELECT plan(1);

SELECT has_function(
  'add_account',
  ARRAY['text']);

SELECT * FROM finish();
ROLLBACK;
