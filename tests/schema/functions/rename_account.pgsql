BEGIN;
SELECT plan(1);

SELECT has_function(
  'rename_account',
  ARRAY['text', 'character varying']);

SELECT * FROM finish();
ROLLBACK;
