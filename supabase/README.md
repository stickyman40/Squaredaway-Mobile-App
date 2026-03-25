# Supabase Schema Notes

## Current Layout

`migrations/20260323120000_initial_schema.sql` is a migration-ready snapshot of the current database schema.

`../supabase_schema.sql` is still kept at the project root so the existing manual apply workflow continues to work.

Going forward, prefer adding new schema changes under `supabase/migrations/`. Treat the root schema file as a convenience snapshot unless you intentionally want to keep both in sync.

## Supabase CLI Setup

Install the Supabase CLI, then initialize this repo for CLI-based migrations:

```bash
brew install supabase/tap/supabase
cd /Users/jaylandstitt/Downloads/SquaredAway
supabase init
```

That creates `supabase/config.toml` and the local Supabase project files.

If you want this repo linked to an existing hosted Supabase project:

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

## Local Development Workflow

Start the local Supabase stack:

```bash
supabase start
```

Apply all migrations to the local database:

```bash
supabase db reset
```

Use `db reset` locally when you want a clean rebuild from the full migration history.

There is also a repo helper script that runs the local start/reset sequence for you:

```bash
./scripts/supabase-reset-local.sh
```

## Remote Development Workflow

After the project is linked, push migrations to the hosted database:

```bash
supabase db push
```

There is also a repo helper script for pushing migrations to the linked remote project:

```bash
./scripts/supabase-push-remote.sh
```

You can also pass extra CLI flags through the script when needed:

```bash
./scripts/supabase-push-remote.sh --dry-run
```

Create each new migration with a timestamped filename:

```bash
supabase migration new describe_change
```

Then add only the incremental SQL for that change to the generated migration file.

## Recommended Workflow

1. Keep `20260323120000_initial_schema.sql` as the baseline migration.
2. Put future schema changes in new files under `supabase/migrations/`.
3. Use `supabase db reset` or `./scripts/supabase-reset-local.sh` for local verification.
4. Use `supabase db push` or `./scripts/supabase-push-remote.sh` for hosted environments.
5. Update `../supabase_schema.sql` only if you still want a single-file snapshot for manual application.
