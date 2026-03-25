# CI Checklist

Use this as a baseline when setting up GitHub Actions, Bitrise, Xcode Cloud, or another CI system.

This repo now includes:

- `.github/workflows/ci.yml` for preflight checks, app builds, and unit tests
- `.github/workflows/ui-tests.yml` for on-demand UI simulator tests
- both workflows upload `.xcresult` bundles as artifacts for debugging

## Repo Checks

- Check out the repo cleanly.
- Confirm required files exist:
  `README.md`, `.env.example`, `supabase/`, `scripts/`, and `docs/`.
- Run `./scripts/preflight-check.sh`.

## Dependency And Tooling Checks

- Confirm Xcode version matches the project requirement.
- Confirm the Supabase CLI is available if the job touches migrations.
- Confirm any required signing or secret configuration is present for the workflow type.

## Database Checks

- Verify migrations exist under `supabase/migrations/`.
- If a local database job is available, run `./scripts/supabase-reset-local.sh`.
- If a protected deploy job is used, run `./scripts/supabase-push-remote.sh` only in the correct environment.

## App Validation

- Build the `SquaredAway` scheme.
- Run unit tests on a known simulator destination.
- Run UI tests in a separate workflow when you want broader app smoke coverage.
- Fail the job on build errors or script failures.

## Manual Follow-Up

- Validate auth flows in the app after schema or auth changes.
- Validate onboarding and dashboard flows after user-profile or routing changes.
- Validate inbox and notification diagnostics after notification-related changes.

## Good Future Additions

- Add a dedicated job for migration validation.
- Add branch protection rules once the pipeline is stable.
