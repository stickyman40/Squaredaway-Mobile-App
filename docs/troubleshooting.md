# Troubleshooting

Use this page for common local setup and workflow issues in `SquaredAway`.

## Supabase CLI Not Found

If a script reports that the Supabase CLI is missing, install it first:

```bash
brew install supabase/tap/supabase
```

## Missing `supabase/config.toml`

If `preflight-check.sh` or `supabase-push-remote.sh` warns that `supabase/config.toml` is missing, initialize and link the local Supabase config:

```bash
supabase init
supabase login
supabase link --project-ref <your-project-ref>
```

## Preflight Warnings About Git Changes

`./scripts/preflight-check.sh` warns when tracked or untracked changes are present. That is expected while you are actively working. Treat it as a reminder to review your diff before handoff, commit, or release.

## Simulator Destination Problems

If an `xcodebuild` test command fails because the simulator destination is unavailable:

1. Open Xcode and make sure the required simulator runtime is installed.
2. Re-run `xcodebuild -showdestinations -project "SquaredAway.xcodeproj" -scheme "SquaredAway"`.
3. Update the local command or workflow destination if the simulator name or OS version changed.

## Auth Callback Or Password Recovery Not Returning To The App

Check that `SUPABASE_REDIRECT_URL` matches:

```text
squaredaway://auth-callback
```

Also confirm the same redirect is configured on the Supabase side for the project you are using.

## Local CI Or UI Test Runs Leave Artifacts Behind

Use the cleanup helper to remove repo-local generated artifacts:

```bash
make clean-local
```

## Need The Common Commands Quickly

Run:

```bash
make help
```

That shows the current local shortcuts for preflight, CI, UI tests, cleanup, and Supabase helpers.
