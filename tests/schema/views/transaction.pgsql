BEGIN;
SELECT plan(6);

SELECT has_view('transaction');

SELECT columns_are(
  'transaction',
  ARRAY['id', 'date', 'text', 'insertion_order']
);

SELECT col_type_is(
  'transaction',
  'id',
  'uuid');

SELECT col_type_is(
  'transaction',
  'date',
  'date');

SELECT col_type_is(
  'transaction',
  'text',
  'text');

SELECT col_type_is(
  'transaction',
  'insertion_order',
  'bigint');

SELECT * FROM finish();
ROLLBACK;
