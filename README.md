# pg_dispatch

> A [TLE](https://github.com/aws/pg_tle) compliant alternative to [pg_later](https://github.com/ChuckHend/pg_later).

An asynchronous task dispatcher for PostgreSQL that helps unblock your main transaction by offloading heavy SQL as deferrable jobs.

This is meant to be a [TLE](https://github.com/aws/pg_tle) compliant alternative to [pg_later](https://github.com/ChuckHend/pg_later) built on top of [`pg_cron`](https://github.com/citusdata/pg_cron), which means you can easily use it in sandboxed environments like Supabase and AWS RDS.

## Use cases

This extension is particularly useful when writing database-native server-side logic (in something like PL/pgSQL) and wanting to dispatch **_side-effects_** asynchronously.

Say you have an `AFTER INSERT` trigger on a user profiles table that is called every time a new user hops in by calling an [RPC (remote procedure call)](https://docs.postgrest.org/en/v12/references/api/functions.html).
You can offload the bulky and asynchronous **_side-effects_** (written as PostgreSQL functions), such as sending notifications to other users or updating large tables storing analytics, thereby unblocking your main RPC, for which btw, the client is still waiting for a response from.

## Prerequisites

- `PostgreSQL` >= v13
- `pg_cron` >= v1.5
- `pgcrypto`

## Installation

Install via [database.dev](https://database.dev/Snehil-Shah/pg_dispatch):

```sql
SELECT dbdev.install(Snehil-Shah@pg_dispatch);
```

> [!WARNING]
> This extension is installed in the `pgdispatch` schema and can potentially cause namespace collisions if you already had one before.

## Usage

```sql
CREATE EXTENSION "Snehil-Shah@pg_dispatch";
```

<!-- <docs> -->
<!-- /<docs> -->

***