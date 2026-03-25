# Release Process

Use this as the high-level flow for preparing and shipping a release.

## 1. Prepare The Change Set

- Confirm the branch contains the intended app, schema, workflow, and doc changes.
- If schema work was included, make sure `supabase/migrations/` is updated.
- If you are still maintaining the manual schema snapshot, update `supabase_schema.sql` too.

## 2. Update Release Notes

- Add a concise summary to `CHANGELOG.md` under `Unreleased`.
- Group notes under `Added`, `Changed`, and `Fixed` when possible.
- Keep entries short and contributor- or user-facing.

## 3. Run Local Verification

- Run `make ci` for the main local CI flow.
- Run `make ui-tests` if the change affects navigation, onboarding, or broader UI behavior.
- Run `make clean-local` afterward if you want to clear generated local artifacts.

## 4. Validate App Behavior

- Follow `docs/release-checklist.md`.
- Confirm auth, onboarding, dashboard, and any touched modules behave correctly.
- Confirm notification diagnostics and the end-to-end probe still behave as expected if notification-related code or schema changed.

## 5. Apply Database Changes

- For local validation, use `make supabase-reset`.
- For hosted environments, use `make supabase-push` when the project is correctly linked.
- Re-check any features that depend on the updated schema after the push.

## 6. Final Review

- Review the diff one last time.
- Make sure the PR summary, testing notes, and rollout impact are clear.
- Use `.github/pull_request_template.md` for consistency if the work is being opened as a PR.

## 7. Handoff Or Ship

- Use `docs/handoff-template.md` if another person will finish or verify the work.
- Use `docs/testing-notes.md` if you want to keep a record of the QA pass.
- Move `CHANGELOG.md` notes from `Unreleased` into a versioned section when you cut the release.
