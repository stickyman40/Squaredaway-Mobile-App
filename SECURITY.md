# Security Policy

If you discover a security issue in `SquaredAway`, please do not open a public GitHub issue with exploit details.

## What To Report

- Authentication bypasses
- Account takeover risks
- Secret or token exposure
- Supabase policy or schema access issues
- CI or automation secret leaks
- Any issue that exposes private user or readiness data

## How To Report

Share a private report with the project maintainer using a non-public channel available to you.

Include:

- A short summary of the issue
- Affected area or file
- Reproduction steps
- Impact
- Suggested mitigation if you have one

## Immediate Secret Exposure Response

If you believe a key, token, or credential was exposed:

1. Rotate the affected secret immediately.
2. Remove or replace the exposed value in the codebase, CI config, or local setup.
3. Review recent commits, pull requests, and workflow logs for additional exposure.
4. Re-run relevant verification steps after the fix.

## Public Issues

For non-sensitive bugs, use the normal GitHub issue templates instead.
