BEGIN;
SELECT plan(2);

SELECT has_view('commodity');

SELECT columns_are(
  'commodity',
  ARRAY['symbol', 'is_prefix', 'has_space']
);

SELECT * FROM finish();
ROLLBACK;
