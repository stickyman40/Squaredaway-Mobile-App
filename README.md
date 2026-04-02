# SquaredAway

SquaredAway is an iOS app for military readiness tracking built with SwiftUI and Supabase.

## What It Includes

- Email auth with onboarding and password recovery deep links
- Dashboard with Promotions, Fitness, Tracker, Chow, Fuel Check, Pay, PCS, Benefits, and Notifications
- Local reminders plus an in-app notification inbox
- PT and fitness tracking with branch-specific test scoring, workout logging, and Apple Health sync
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

The app also includes Apple Health integration for the PT module. The project is configured with:

- `NSHealthShareUsageDescription`
- `SquaredAway/SquaredAway.entitlements`

To override them in Xcode:

1. Open the `SquaredAway` scheme.
2. Edit the Run action.
3. Add the environment variables above.

The `barcode-lookup` Supabase Edge Function can also use RapidAPI as an optional Fuel Check product source before falling back to Open Food Facts. Configure these function secrets when you want that behavior:

- `RAPIDAPI_KEY`
- `RAPIDAPI_HOST` (defaults to `big-product-data.p.rapidapi.com`)
- `RAPIDAPI_PRODUCT_PATH_TEMPLATE` (defaults to `/gtin/{barcode}`)
- `RAPIDAPI_FOOD_PATH_TEMPLATE` (for DietaGram food search, defaults to `/apiFood.php?name={query}` when `RAPIDAPI_HOST` is `dietagram.p.rapidapi.com`)
- `USDA_API_KEY` (for USDA FoodData Central search enrichment and weak-result fallback)

The `request-account-deletion` Edge Function sends the final destructive confirmation email for account deletion. Configure these function secrets before deploying it:

- `RESEND_API_KEY`
- `ACCOUNT_DELETE_FROM_EMAIL`
- `ACCOUNT_DELETE_FROM_NAME` (optional, defaults to `SquaredAway`)
- `ACCOUNT_DELETE_REDIRECT_URL` (optional, defaults to `squaredaway://auth-callback`)

For password recovery and auth callbacks, the redirect URL should match the app deep link format:

```text
squaredaway://auth-callback
```

## Database Workflow

The repo now includes a Supabase migrations layout under `supabase/`.

- Baseline migration: `supabase/migrations/20260323120000_initial_schema.sql`
- PT module migration: `supabase/migrations/20260328120000_pt_fitness_module.sql`
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

Refresh all cached Fuel Check products so existing barcodes pick up the latest source-selection and scoring rules:

```bash
./scripts/backfill-fuel-products.sh
```

Optional environment overrides:

- `FUEL_BATCH_SIZE` to control paging size
- `FUEL_START_OFFSET` to resume later in the catalog
- `FUEL_MAX_PRODUCTS` to cap a single run
- `FUEL_STALE_DAYS` to refresh only products older than a given age
- `FUEL_SLEEP_SECONDS` to slow requests down if needed

There is also a GitHub Actions workflow at `.github/workflows/fuel-check-refresh.yml` that can run this refresh on demand or weekly. If you want it to use repository secrets instead of the built-in defaults, add:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

The scheduled workflow uses `FUEL_STALE_DAYS=14` so it only revisits older cached products by default.
Manual runs from the GitHub Actions UI can also set `stale_days`, `max_products`, and `batch_size`.
GitHub runs also publish a short refresh summary with processed, succeeded, and failed counts.

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
