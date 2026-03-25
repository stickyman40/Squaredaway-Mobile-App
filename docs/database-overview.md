# Database Overview

`SquaredAway` uses Supabase Postgres for auth-linked profile data, readiness tracking, and the in-app notification pipeline.

## Schema Sources

The current schema is represented in two places:

- `supabase/migrations/20260323120000_initial_schema.sql`
- `supabase/migrations/20260323153000_feature_modules_and_onboarding_attribution.sql`
- `supabase/migrations/20260323162000_module_notification_triggers_and_profile_attribution_settings.sql`
- `supabase/migrations/20260323170000_chow_branding_copy_updates.sql`
- `supabase_schema.sql`

The migration file is the preferred forward path. The root schema file is kept as a convenience snapshot for the existing manual workflow.

## Core Relationship

The central relationship is:

- `auth.users`
  -> `users_profile`
  -> feature tables and notifications

`users_profile.id` matches the authenticated Supabase user ID and acts as the parent record for most app data.

## Main Tables

### `users_profile`

Stores the user’s app profile and onboarding state:

- email
- branch, rank, MOS/rating
- discovery source and acquisition notes
- height and weight
- fitness goal
- onboarding completion

### `fitness_logs`

Stores workout history per user, including exercise type, duration, optional score, notes, and log timestamp.

### `nutrition_logs`

Stores meal and macro data per user for the user-facing Chow module, including meal type, calories, protein, carbs, fat, notes, and log timestamp.

### `promotions_data`

Stores promotion-readiness information such as current rank, target rank, points, board date, and notes.

### `pay_data`

Stores pay grade plus compensation components like base pay, BAH, and BAS.

### `tracker_data`

Stores assignment-tracking details such as duty station, duty status, next milestone, optional report date, and notes.

### `pcs_data`

Stores PCS planning details such as origin, destination, optional move date, and logistics checklist fields.

### `benefits_data`

Stores benefits-readiness status such as health coverage, GI Bill, TSP, family support, and notes.

### `notifications`

Stores in-app inbox notifications shown in the app.

Key fields:

- `type` for the notification category (`milestones`, `readiness`, or `activity`)
- `title`
- `body`
- `is_read`
- `created_at`

### `notification_preferences`

Stores server-side notification category preferences for:

- milestones
- readiness
- activity

## Automatic Data Setup

The schema includes `handle_new_user()` so new auth users automatically get:

- a `users_profile` row
- a `notification_preferences` row

There is also a backfill insert for existing users so preference rows can be created safely when the schema is re-applied.

## Notification Pipeline

The database notification flow is intentionally server-driven.

Key helper functions:

- `notification_category_enabled(...)`
- `create_system_notification(...)`
- `run_notification_pipeline_probe()`

Key trigger handlers:

- onboarding completion
- promotion changes
- pay changes
- fitness log changes
- chow log changes
- tracker changes
- PCS changes
- benefits changes

These triggers write to `notifications` when the relevant category is enabled for the current user, and they populate the `type` column so the app can categorize inbox items consistently.

## Security Model

The schema enables row-level security on the app tables and restricts most access to the authenticated owner of the row.

This includes:

- profile access
- feature data access
- notifications
- notification preferences

There are also explicit function grants for authenticated users on the supported RPC paths such as account deletion and the notification probe.

## Operational Notes

- Use `make supabase-reset` for local schema rebuilds.
- Use `make supabase-push` for linked remote environments.
- Use `docs/release-checklist.md` and `docs/release-process.md` when shipping schema changes.
