BEGIN;
SELECT plan(5);

SELECT has_view('formula_term');

SELECT columns_are(
  'formula_term',
  ARRAY['formula_id', 'account_full_name', 'positive']
);

SELECT col_type_is(
  'formula_term',
  'formula_id',
  'uuid');

SELECT col_type_is(
  'formula_term',
  'account_full_name',
  'text');

SELECT col_type_is(
  'formula_term',
  'positive',
  'boolean');

SELECT * FROM finish();
ROLLBACK;
