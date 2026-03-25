# Service Overview

This page summarizes the shared service layer used by `SquaredAway`.

## Service Groups

There are two main service categories:

- Supabase-backed services under `SquaredAway/Core/Supabase`
- Local device helpers under `SquaredAway/Core/Notifications`

## Supabase Core

### `SupabaseManager`

Responsibilities:

- owns the shared `SupabaseClient`
- reads `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_REDIRECT_URL`
- parses auth callback URLs
- centralizes table-name constants

This is the foundation that the other Supabase-backed services use.

### `AuthService`

Responsibilities:

- sign up
- sign in
- sign out
- resend verification
- restore session
- send password reset
- update email
- update password
- delete account through RPC

This is the main bridge between the app and Supabase Auth.

### `ProfileService`

Responsibilities:

- fetch profile
- create profile
- update profile
- sync profile email
- mark onboarding complete

Primary table:

- `users_profile`

### `PromotionService`

Responsibilities:

- create, fetch, update, and delete promotion data
- support promotion-readiness summaries in the dashboard and feature view

Primary table:

- `promotions_data`

### `FitnessService`

Responsibilities:

- create, fetch, update, and delete fitness logs
- support fitness summaries and trend displays

Primary table:

- `fitness_logs`

### `NutritionService`

Responsibilities:

- create, fetch, update, and delete chow logs
- support meal/macro summaries and trend displays

Primary table:

- `nutrition_logs`

### `TrackerService`

Responsibilities:

- create, fetch, update, and delete tracker data
- support assignment summaries and readiness progress

Primary table:

- `tracker_data`

### `PCSService`

Responsibilities:

- create, fetch, update, and delete PCS planning data
- support logistics summaries and completion tracking

Primary table:

- `pcs_data`

### `BenefitsService`

Responsibilities:

- create, fetch, update, and delete benefits readiness data
- support coverage summaries and completion tracking

Primary table:

- `benefits_data`

### `PayService`

Responsibilities:

- create, fetch, update, and delete pay data
- support pay summaries and dashboard breakdowns

Primary table:

- `pay_data`

### `NotificationService`

Responsibilities:

- fetch inbox notifications
- compute unread counts
- mark one or all as read
- delete one or all notifications
- seed sample notifications
- run the server-side notification pipeline probe
- optionally create notifications with duplicate suppression

Primary table:

- `notifications`

This service sits at the center of the in-app inbox experience.

### `NotificationPreferencesService`

Responsibilities:

- fetch server-side notification preferences
- upsert notification preference records

Primary table:

- `notification_preferences`

This service keeps inbox-category preferences synced with Supabase.

## Local Device Helpers

### `ReminderService`

Responsibilities:

- request device notification authorization
- schedule or remove daily workout reminders
- schedule or remove daily meal reminders
- schedule or remove promotion board reminders
- inspect notification authorization state

This service is device-local and uses `UserNotifications`.

### `ReminderPreferences`

Responsibilities:

- store local reminder configuration in `UserDefaults`
- provide the preferred reminder times and toggle state used by `ReminderService`

### `NotificationPreferences`

Responsibilities:

- store local notification category toggles in `UserDefaults`
- define the app’s inbox categories:
  `milestones`, `readiness`, `activity`

This works alongside `NotificationPreferencesService`, which stores the server-side copy.

## How Services Are Used

- `AuthViewModel` is the main coordinator for auth and profile state.
- Feature views typically call one or more singleton services directly.
- Dashboard and settings pull together several services at once because they aggregate data across the app.

## Design Trade-Off

The project currently uses simple singleton services instead of a heavier dependency-injection setup. That keeps the app straightforward, but also means service boundaries and responsibilities are important for keeping the codebase understandable as the app grows.
