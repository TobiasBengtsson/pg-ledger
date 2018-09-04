BEGIN;
SELECT plan(2);

SELECT has_function(
  'add_commodity',
  ARRAY['character varying']);

SELECT has_function(
  'add_commodity',
  ARRAY['character varying', 'boolean', 'boolean']);

SELECT * FROM finish();
ROLLBACK;
