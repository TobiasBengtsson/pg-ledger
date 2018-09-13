BEGIN;
SELECT plan(2);

SELECT has_function(
  'edit_commodity',
  ARRAY['character varying', 'character varying', 'boolean', 'boolean']);

SELECT has_function(
  'edit_commodity',
  ARRAY['character varying', 'character varying']);

SELECT * FROM finish();
ROLLBACK;
