\echo Use `CREATE EXTENSION pg_dispatch` to load this file. \quit

/**
 * (internal) ### pgdispatch
 *
 * Asynchronous SQL dispatcher.
 *
 * #### Dependencies:
 *   - `pg_cron` extension must be installed and configured.
 *   - `pgcrypto` extension for UUID generation.
 *
 * #### Public Functions:
 *   - `pgdispatch.fire(command TEXT)`
 *   - `pgdispatch.snooze(command TEXT, delay INTERVAL)`
 *
 * #### Internal Functions:
 *   - `pgdispatch._schedule_job(command TEXT, delay INTERVAL)`
 */
CREATE SCHEMA IF NOT EXISTS pgdispatch;
COMMENT ON SCHEMA pgdispatch IS
'Reserved for the pg_dispatch extension';

/**
 * (internal) ### pgdispatch._schedule_job( command TEXT, delay INTERVAL )
 *
 * Internal function for scheduling temporary cron jobs.
 *
 * #### Parameters:
 *   - **command** (`TEXT`) - The SQL statement to execute
 *   - **delay** (`INTERVAL`) - How long to delay the execution (truncates to seconds precision)
 *
 * #### Returns:
 *   - `VOID`
 */
CREATE OR REPLACE FUNCTION pgdispatch._schedule_job(command TEXT, delay INTERVAL)
RETURNS VOID AS $$
DECLARE
    MINIMUM_PERMISSIBLE_DELAY_IN_SECONDS INT = 1;
    job_id TEXT := gen_random_uuid()::text;
    seconds_delay INT;
    cron_schedule TEXT;
    sleep_command TEXT := '';
BEGIN
    -- Convert interval to seconds
    seconds_delay := GREATEST(EXTRACT(EPOCH FROM delay)::INT, MINIMUM_PERMISSIBLE_DELAY_IN_SECONDS);

    -- If delay is more than 59 seconds, we need to use sleep inside the job itself
    IF seconds_delay > 59 THEN
        cron_schedule := '59 seconds';
        -- Calculate remaining seconds to sleep
        sleep_command := format('PERFORM pg_sleep(%L);', seconds_delay - 59);
    ELSE
        cron_schedule := format('%s seconds', seconds_delay);
    END IF;

    PERFORM cron.schedule(
        job_name := job_id,
        schedule := cron_schedule,
        command := format($cmd$
            DO $job$
            BEGIN
                %s -- Sleep to ensure the job runs after the specified delay

                -- Execute the main command safely
                BEGIN
                    EXECUTE %L;
                EXCEPTION
                    WHEN OTHERS THEN
                    NULL;
                END;

                -- Clean up cron artifacts
                DELETE FROM cron.job_run_details
                WHERE jobid IN (
                    SELECT jobid
                    FROM cron.job
                    WHERE jobname = %L
                );
                PERFORM cron.unschedule(job_name := %L);
            END;
            $job$;
        $cmd$, sleep_command, command, job_id, job_id)
    );
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION pgdispatch._schedule_job(TEXT, INTERVAL) IS
'Internal function for cron job scheduling - use pg_dispatch.fire or pg_dispatch.snooze instead';

/**
 * ### pgdispatch.fire( command TEXT )
 *
 * Dispatches an SQL command for asynchronous execution.
 *
 * ```sql
 * SELECT pgdispatch.fire('SELECT pg_sleep(40);');
 * ```
 *
 * #### Parameters
 *   - **command** (`TEXT`) - The SQL statement to dispatch
 *
 * #### Returns:
 *   - `VOID`
 */
CREATE OR REPLACE FUNCTION pgdispatch.fire(command TEXT)
RETURNS VOID AS $$
BEGIN
    -- Schedule the job with a delay of 0 seconds
    PERFORM pgdispatch._schedule_job(command, '0 seconds');
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION pgdispatch.fire(TEXT) IS
'Dispatch an SQL command for asynchronous execution';

/**
 * ### pgdispatch.snooze( command TEXT, delay INTERVAL )
 *
 * Dispatches a delayed SQL command for asynchronous execution.
 *
 * ```sql
 * SELECT pgdispatch.snooze('SELECT pg_sleep(20);', '20 seconds');
 * ```
 *
 * **Note**: The delay is scheduled asynchronously and will not block your main transaction.
 *
 * #### Parameters:
 *   - **command** (`TEXT`) - The SQL statement to dispatch
 *   - **delay** (`INTERVAL`) - How long to delay the execution (truncates to seconds precision)
 *
 * #### Returns:
 *   - `VOID`
 */
CREATE OR REPLACE FUNCTION pgdispatch.snooze(command TEXT, delay INTERVAL)
RETURNS VOID AS $$
BEGIN
    -- Schedule the job with the specified delay
    PERFORM pgdispatch._schedule_job(command, delay);
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION pgdispatch.snooze(TEXT, INTERVAL) IS
'Dispatch a delayed SQL command for asynchronous execution';