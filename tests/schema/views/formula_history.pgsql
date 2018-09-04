BEGIN;
SELECT plan(2);

SELECT has_view('formula_history');

SELECT columns_are(
  'formula_history',
  ARRAY['id', 'date', 'symbol', 'sum']
);

SELECT * FROM finish();
ROLLBACK;
