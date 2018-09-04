BEGIN;
SELECT plan(5);

SELECT has_view('commodity');

SELECT columns_are(
  'commodity',
  ARRAY['symbol', 'is_prefix', 'has_space']
);

SELECT col_type_is(
  'commodity',
  'symbol',
  'character varying(20)');

SELECT col_type_is(
  'commodity',
  'is_prefix',
  'boolean');

SELECT col_type_is(
  'commodity',
  'has_space',
  'boolean');

SELECT * FROM finish();
ROLLBACK;
