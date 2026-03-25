# Release Checklist

Use this checklist before shipping app or schema changes.

## Supabase

- Confirm your local changes are represented in `supabase/migrations/`.
- If you are still maintaining it, update `supabase_schema.sql` to match the latest schema state.
- Run local verification with `./scripts/supabase-reset-local.sh`.
- Push hosted schema changes with `./scripts/supabase-push-remote.sh`.

## App Launch

- Open `SquaredAway.xcodeproj` and run the `SquaredAway` scheme.
- Verify the app launches without crashing.
- Confirm the configured `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_REDIRECT_URL` are correct for the target environment.

## Authentication

- Sign in with an existing test account.
- Sign up with a new test account if auth-related changes were made.
- Trigger a password reset email.
- Open the recovery link and confirm the app routes into the password recovery flow.
- Set a new password successfully and verify sign-in still works.

## Core App Areas

- Complete onboarding for a fresh account.
- Confirm onboarding captures discovery source / acquisition notes.
- Verify the dashboard loads after onboarding.
- Open Promotions, Fitness, Chow, Pay, Tracker, PCS, Benefits, and Settings.
- Create or update at least one record in each area touched by your changes.

## Notifications And Diagnostics

- Open the in-app inbox and confirm it loads.
- In Settings, run `Notification Diagnostics`.
- Run `Run End-to-End Probe` and confirm a probe notification is created when readiness notifications are enabled.
- Use `Copy Diagnostics Summary` if you need a shareable status snapshot.
- If local reminder behavior changed, verify notification permission status and reminder scheduling from Settings.

## Final Sanity Check

- Run `./scripts/preflight-check.sh`.
- Confirm new copy, labels, and buttons read cleanly in the UI.
- Check for any obvious navigation dead ends or stuck loading states.
- Review the diff before commit or handoff.
