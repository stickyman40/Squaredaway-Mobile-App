# SquaredAway

SquaredAway is an iOS app for military readiness tracking built with SwiftUI and Supabase.

## What It Includes

- Email auth with onboarding and password recovery deep links
- Dashboard with Promotions, Fitness, Chow, Pay, Tracker, PCS, Benefits, and Notifications
- Local reminders plus an in-app notification inbox
- Supabase-backed profile, readiness, and notification preference storage

## Project Info

- App target: `SquaredAway`
- Bundle ID: `DBB-Labs-LLC.SquaredAway`
- Version: `1.0`
- iOS deployment target: `18.5`

## Open The App

Open `SquaredAway.xcodeproj` in Xcode and run the `SquaredAway` scheme on an iOS simulator or device.

## Supabase App Configuration

The app reads these environment variables at launch:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_REDIRECT_URL`

There is a reference file at `.env.example` with placeholder values for those keys.

If they are not set, the app falls back to values already defined in `SquaredAway/Core/Supabase/SupabaseManager.swift`.

To override them in Xcode:

1. Open the `SquaredAway` scheme.
2. Edit the Run action.
3. Add the environment variables above.

The `barcode-lookup` Supabase Edge Function can also use RapidAPI as an optional Fuel Check product source before falling back to Open Food Facts. Configure these function secrets when you want that behavior:

- `RAPIDAPI_KEY`
- `RAPIDAPI_HOST` (defaults to `big-product-data.p.rapidapi.com`)
- `RAPIDAPI_PRODUCT_PATH_TEMPLATE` (defaults to `/gtin/{barcode}`)

For password recovery and auth callbacks, the redirect URL should match the app deep link format:

```text
squaredaway://auth-callback
```

## Database Workflow

The repo now includes a Supabase migrations layout under `supabase/`.

- Baseline migration: `supabase/migrations/20260323120000_initial_schema.sql`
- Manual schema snapshot: `supabase_schema.sql`
- Supabase workflow notes: `supabase/README.md`

## Helpful Commands

Reset the local Supabase stack and rebuild the local database from migrations:

```bash
./scripts/supabase-reset-local.sh
```

Push migrations to a linked remote Supabase project:

```bash
./scripts/supabase-push-remote.sh
```

Run a lightweight repo preflight before handoff or release:

```bash
./scripts/preflight-check.sh
```

Run the same preflight, build, and unit-test sequence used by the main CI workflow:

```bash
./scripts/ci-local.sh
```

Run the same UI-test sequence used by the manual UI workflow:

```bash
./scripts/ui-tests-local.sh
```

Use `make help` to see the shortcut targets for the common local workflows.

Use `make clean-local` to remove generated test results and local build artifacts inside the repo.

## Additional Docs

- Changelog: `CHANGELOG.md`
- Docs index: `docs/README.md`
- Scripts index: `scripts/README.md`
- Architecture overview: `docs/architecture-overview.md`
- Database overview: `docs/database-overview.md`
- Feature overview: `docs/feature-overview.md`
- Service overview: `docs/service-overview.md`
- Contributing guide: `CONTRIBUTING.md`
- Security policy: `SECURITY.md`
- Release process: `docs/release-process.md`
- Release checklist: `docs/release-checklist.md`
- Handoff template: `docs/handoff-template.md`
- Testing notes template: `docs/testing-notes.md`
- CI checklist: `docs/ci-checklist.md`
- Troubleshooting guide: `docs/troubleshooting.md`

## Recommended Setup Flow

1. Open `SquaredAway.xcodeproj` in Xcode.
2. Copy values from `.env.example` and configure `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_REDIRECT_URL` in the scheme if needed.
3. Follow `supabase/README.md` to initialize or link the Supabase CLI.
4. Run `./scripts/supabase-reset-local.sh` for local database setup, or apply `supabase_schema.sql` manually if you are staying on the old workflow.
5. Run the app and sign up with a test account.
