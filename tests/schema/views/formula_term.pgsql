BEGIN;
SELECT plan(2);

SELECT has_view('formula_term');

SELECT columns_are(
  'formula_term',
  ARRAY['formula_id', 'account_full_name', 'positive']
);

SELECT * FROM finish();
ROLLBACK;
