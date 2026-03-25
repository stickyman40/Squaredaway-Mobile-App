# Contributing

Thanks for contributing to `SquaredAway`.

## Before You Start

- Read `README.md` for project setup.
- Use `.env.example` as a reference for Supabase-related environment variables.
- If your work touches the database, review `supabase/README.md`.

## Recommended Workflow

1. Create a focused branch for your change.
2. Make the smallest practical change that solves the problem.
3. Update docs when setup, workflow, schema, or testing expectations change.
4. Keep `supabase/migrations/` current for schema changes.
5. Update `supabase_schema.sql` too if you are still maintaining the manual snapshot workflow.

## Local Checks

Run these before opening a pull request:

```bash
make ci
```

If you prefer script-level or step-by-step commands, `make ci` wraps:

```bash
./scripts/preflight-check.sh
xcodebuild -project "SquaredAway.xcodeproj" -scheme "SquaredAway" -destination "generic/platform=iOS Simulator" build
xcodebuild test -project "SquaredAway.xcodeproj" -scheme "SquaredAway" -only-testing:"SquaredAwayTests" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"
```

Run the UI test workflow locally when your change affects navigation, onboarding, or broader app behavior:

```bash
make ui-tests
```

## Pull Requests

- Use the PR template in `.github/pull_request_template.md`.
- Summarize what changed and why.
- List what you verified locally.
- Call out schema, environment, or rollout impact clearly.

## Helpful Docs

- `docs/release-checklist.md`
- `docs/handoff-template.md`
- `docs/testing-notes.md`
- `docs/ci-checklist.md`
