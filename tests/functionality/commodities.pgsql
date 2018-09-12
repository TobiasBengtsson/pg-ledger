BEGIN;
SELECT plan(4);

SELECT add_commodity('$', true, false);
SELECT add_commodity('SEK', false, true);
SELECT add_commodity('GBP ');
SELECT add_commodity(' HK$', true, true);
SELECT add_commodity('  kr ', false, false);

SELECT results_eq(
  'SELECT symbol::text, is_prefix, has_space
  FROM commodity
  ORDER BY symbol;',
  'SELECT * FROM (VALUES
    (''$'', true, false),
    (''GBP'', false, true),
    (''HK$'', true, true),
    (''kr'', false, false),
    (''SEK'', false, true)
  ) AS t (symbol, is_prefix, has_space)',
  'Commodities should be added correctly, with default values is_prefix=false and has_space=true and trimming whitespace from symbol');

SELECT results_eq(
  'SELECT delete_commodity(''GBP'')',
  ARRAY[true],
  'delete_commodity should return true'
);

SELECT delete_commodity('GBP');

SELECT results_eq(
  'SELECT symbol::text, is_prefix, has_space
  FROM commodity
  ORDER BY symbol;',
  'SELECT * FROM (VALUES
    (''$'', true, false),
    (''HK$'', true, true),
    (''kr'', false, false),
    (''SEK'', false, true)
  ) AS t (symbol, is_prefix, has_space)',
  'delete_commodity should delete commodity');

SELECT add_account('DummyAccount');

SELECT add_transaction(
  '2018-09-12',
  'TestTransaction',
  ROW('DummyAccount', 1, '$'),
  ROW('DummyAccount', -1, '$'));

SELECT throws_ok(
  'SELECT delete_commodity(''$'')',
  '23503',
  'update or delete on table "commodity" violates foreign key constraint "transaction_row_commodity_fkey" on table "transaction_row"',
  'delete_commodity should result in FK violation error if commodity is used by a transaction');

SELECT * FROM finish();
ROLLBACK;
