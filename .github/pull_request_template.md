## Summary

- What changed?
- Why was it changed?

## Testing

- [ ] `./scripts/preflight-check.sh`
- [ ] `xcodebuild -project "SquaredAway.xcodeproj" -scheme "SquaredAway" -destination "generic/platform=iOS Simulator" build`
- [ ] `xcodebuild test -project "SquaredAway.xcodeproj" -scheme "SquaredAway" -only-testing:"SquaredAwayTests" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6"`
- [ ] Manual app verification completed

## App Areas Checked

- [ ] Authentication
- [ ] Onboarding
- [ ] Dashboard
- [ ] Promotions
- [ ] Fitness
- [ ] Chow
- [ ] Pay
- [ ] Tracker
- [ ] PCS
- [ ] Benefits
- [ ] Notifications
- [ ] Settings

## Supabase Impact

- [ ] No schema changes
- [ ] Updated `supabase/migrations/`
- [ ] Updated `supabase_schema.sql`
- [ ] Requires `supabase db push`
- [ ] Requires environment/config changes

## Reviewer Notes

- Risks:
- Follow-ups:
- Rollout notes:
