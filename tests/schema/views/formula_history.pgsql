BEGIN;
SELECT plan(6);

SELECT has_view('formula_history');

SELECT columns_are(
  'formula_history',
  ARRAY['id', 'date', 'symbol', 'sum']
);

SELECT col_type_is(
  'formula_history',
  'id',
  'uuid');

SELECT col_type_is(
  'formula_history',
  'date',
  'date');

SELECT col_type_is(
  'formula_history',
  'symbol',
  'character varying(20)');

SELECT col_type_is(
  'formula_history',
  'sum',
  'numeric');

SELECT * FROM finish();
ROLLBACK;
