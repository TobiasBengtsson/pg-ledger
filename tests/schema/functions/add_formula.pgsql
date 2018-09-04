BEGIN;
SELECT plan(1);

SELECT has_function(
  'add_formula',
  ARRAY['text']);

SELECT * FROM finish();
ROLLBACK;
