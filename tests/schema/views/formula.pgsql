BEGIN;
SELECT plan(2);

SELECT has_view('formula');

SELECT columns_are(
  'formula',
  ARRAY['id', 'name']
);

SELECT * FROM finish();
ROLLBACK;
