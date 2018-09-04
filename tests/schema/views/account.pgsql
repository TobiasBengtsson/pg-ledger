BEGIN;
SELECT plan(5);

SELECT has_view('account');

SELECT columns_are(
  'account',
  ARRAY['full_name', 'parent_name', 'name']
);

SELECT col_type_is(
  'account',
  'full_name',
  'text');

SELECT col_type_is(
  'account',
  'parent_name',
  'text');

SELECT col_type_is(
  'account',
  'name',
  'character varying(100)');

SELECT * FROM finish();
ROLLBACK;
