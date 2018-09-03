-- Start transaction and plan the tests.
BEGIN;
SELECT plan(1);

-- Run the tests.
SELECT pass( 'Hello from test1' );

-- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
