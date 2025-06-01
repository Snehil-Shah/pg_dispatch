-- pgdispatch.snooze integration test
-- Note: This test cannot run in a transaction due to pg_cron isolation requirements

-- Ensure pgTAP is loaded
SELECT plan(18);

-- Ensure pg_cron is ready (check for required tables)
SELECT has_table('cron', 'job', 'pg_cron job table should exist');
SELECT has_table('cron', 'job_run_details', 'pg_cron job_run_details table should exist');

-- Ensure pgdispatch schema exists
SELECT has_schema('pgdispatch', 'pgdispatch schema should exist');

-- Ensure the fire function exists in pgdispatch
SELECT has_function('pgdispatch', 'snooze', ARRAY['text', 'interval'], 'pgdispatch.snooze function should exist');

-- Create a test table (must be permanent for cron job to see it)
CREATE TABLE test_pgdispatch(value TEXT);

-- Store initial job counts for comparison
CREATE TEMP TABLE initial_counts AS
SELECT
    (SELECT COUNT(*) FROM cron.job) as job_count,
    (SELECT COUNT(*) FROM cron.job_run_details) as job_run_count;

-- Schedule a delayed valid insert using pgdispatch
SELECT pgdispatch.snooze(
$$
    SELECT pg_sleep(5);
    INSERT INTO test_pgdispatch VALUES ('123');
$$
, '5 seconds'
);

-- Wait 3 seconds and check job creation
DO $$
BEGIN
  PERFORM pg_sleep(3);
END
$$;

-- Check if a new job was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts) + 1,
  'exactly one new job was scheduled in cron.job'
);

-- Check if no job run detail was created yet
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts),
  'no job run detail was created yet in cron.job_run_details yet'
);

-- Check if the test table is still empty (job hasn't completed yet)
SELECT is(
  (SELECT COUNT(*) FROM test_pgdispatch),
  0::bigint,
  'test table should still be empty after 3 seconds'
);

-- Wait 4 more seconds for the snooze to complete
DO $$
BEGIN
  PERFORM pg_sleep(4);
END
$$;

-- Check if exactly one new job was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts) + 1,
  'exactly one new job was scheduled in cron.job'
);

-- Check if exactly one new job run detail was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts) + 1,
  'exactly one job run detail was created in cron.job_run_details'
);

-- Wait 4 more seconds for job to complete
DO $$
BEGIN
  PERFORM pg_sleep(4);
END
$$;

-- Check if job table was cleaned up
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts),
  'cron.job should return to initial state after job completes (job cleaned up)'
);

-- Check if job_run_details was also cleaned up
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts),
  'cron.job_run_details should return to initial state (history cleared)'
);

-- Check if the test value was inserted
SELECT is(
  (SELECT value FROM test_pgdispatch LIMIT 1),
  '123',
  'test table should contain the inserted value after job completion'
);

-- Cleanup: Remove test table
DROP TABLE IF EXISTS test_pgdispatch CASCADE;

-- Schedule an invalid SQL using pgdispatch
SELECT pgdispatch.snooze(
$$
    SELECT pg_sleep(5);
    SELECT invalid_reference; -- This will fail
$$,
'5 seconds'
);

-- Wait 3 seconds and check job creation
DO $$
BEGIN
  PERFORM pg_sleep(3);
END
$$;

-- Check if a new job was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts) + 1,
  'exactly one new job was scheduled in cron.job'
);

-- Check if no job run detail was created yet
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts),
  'no job run detail was created yet in cron.job_run_details yet'
);

-- Wait 4 more seconds for the snooze to complete
DO $$
BEGIN
  PERFORM pg_sleep(4);
END
$$;

-- Check if exactly one new job was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts) + 1,
  'exactly one new job was scheduled in cron.job'
);

-- Check if exactly one new job run detail was created
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts) + 1,
  'exactly one job run detail was created in cron.job_run_details'
);

-- Wait 4 more seconds for job to complete
DO $$
BEGIN
  PERFORM pg_sleep(4);
END
$$;

-- Check if job table was cleaned up
SELECT is(
  (SELECT COUNT(*) FROM cron.job),
  (SELECT job_count FROM initial_counts),
  'cron.job should return to initial state after job completes (job cleaned up)'
);

-- Check if job_run_details was also cleaned up
SELECT is(
  (SELECT COUNT(*) FROM cron.job_run_details),
  (SELECT job_run_count FROM initial_counts),
  'cron.job_run_details should return to initial state (history cleared)'
);

-- Finish test
SELECT * FROM finish();