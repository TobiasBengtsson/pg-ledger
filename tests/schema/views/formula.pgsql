BEGIN;
SELECT plan(4);

SELECT has_view('formula');

SELECT columns_are(
  'formula',
  ARRAY['id', 'name']
);

SELECT col_type_is(
  'formula',
  'id',
  'uuid');

SELECT col_type_is(
  'formula',
  'name',
  'text');

SELECT * FROM finish();
ROLLBACK;
