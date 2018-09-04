BEGIN;
SELECT plan(5);

SELECT has_type('add_transaction_row');

SELECT columns_are(
  'add_transaction_row',
  ARRAY[ 'account_full_name', 'amount', 'commodity' ]
);

SELECT col_type_is(
  'add_transaction_row',
  'account_full_name',
  'text');

SELECT col_type_is(
  'add_transaction_row',
  'amount',
  'numeric(38,18)');

SELECT col_type_is(
  'add_transaction_row',
  'commodity',
  'character varying(20)');

SELECT * FROM finish();
ROLLBACK;
