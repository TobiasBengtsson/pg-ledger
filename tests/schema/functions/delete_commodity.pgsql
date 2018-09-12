BEGIN;
SELECT plan(1);

SELECT has_function(
  'delete_commodity',
  ARRAY['character varying']);

SELECT * FROM finish();
ROLLBACK;
