# Scripts Index

This folder contains local helper scripts for common development and verification tasks.

## Available Scripts

- `preflight-check.sh`: Check repo basics, helper script availability, Supabase CLI/config presence, and git working tree status
- `ci-local.sh`: Run the local equivalent of the main CI workflow
- `ui-tests-local.sh`: Run the local equivalent of the manual UI-test workflow
- `clean-local.sh`: Remove repo-local generated artifacts like `TestResults`, `build`, and `.build`
- `supabase-reset-local.sh`: Start local Supabase services and rebuild the local database from migrations
- `supabase-push-remote.sh`: Push migrations to a linked remote Supabase project

## Related Shortcuts

Use `make help` to see the matching `make` targets for the most common script workflows.
