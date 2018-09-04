BEGIN;
SELECT plan(2);

SELECT has_view('transaction');

SELECT columns_are(
  'transaction',
  ARRAY['id', 'date', 'text', 'insertion_order']
);

SELECT * FROM finish();
ROLLBACK;
