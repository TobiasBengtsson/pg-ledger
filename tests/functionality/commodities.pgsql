BEGIN;
SELECT plan(1);

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

SELECT * FROM finish();
ROLLBACK;
