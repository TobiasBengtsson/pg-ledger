BEGIN;
SELECT plan(2);

SELECT has_view('account');

SELECT columns_are(
  'account',
  ARRAY['full_name', 'parent_name', 'name']
);

SELECT * FROM finish();
ROLLBACK;
