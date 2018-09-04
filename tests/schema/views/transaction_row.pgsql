BEGIN;
SELECT plan(7);

SELECT has_view('transaction_row');

SELECT columns_are(
  'transaction_row',
  ARRAY['id', 'transaction_id', 'account_name', 'amount', 'commodity']
);

SELECT col_type_is(
  'transaction_row',
  'id',
  'uuid');

SELECT col_type_is(
  'transaction_row',
  'transaction_id',
  'uuid');

SELECT col_type_is(
  'transaction_row',
  'account_name',
  'text');

SELECT col_type_is(
  'transaction_row',
  'amount',
  'numeric(38,18)');

SELECT col_type_is(
  'transaction_row',
  'commodity',
  'character varying(20)');

SELECT * FROM finish();
ROLLBACK;
