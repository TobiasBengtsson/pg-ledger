BEGIN;
SELECT plan(1);

SELECT has_function(
  'add_formula_term',
  ARRAY['uuid', 'text', 'boolean']);

SELECT * FROM finish();
ROLLBACK;
