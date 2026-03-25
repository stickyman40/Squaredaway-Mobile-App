# Architecture Overview

`SquaredAway` is a SwiftUI iOS app backed by Supabase for auth, profile data, readiness data, and in-app notifications.

## High-Level Structure

- `SquaredAway/SquaredAwayApp.swift`: App entry point, UIKit appearance setup, and notification defaults
- `SquaredAway/ContentView.swift`: Root router for splash, auth, onboarding, password recovery, and dashboard states
- `SquaredAway/Core/Models`: Shared app models and state enums
- `SquaredAway/Core/Supabase`: Supabase client wrapper plus feature-specific services
- `SquaredAway/Core/Notifications`: Local reminder and notification preference helpers
- `SquaredAway/Features`: Screen-level UI grouped by feature

## App Flow

1. `SquaredAwayApp` boots the app and configures appearance and notification defaults.
2. `ContentView` owns `AuthViewModel` and switches between:
   - splash
   - login
   - email verification
   - password recovery
   - onboarding
   - dashboard
3. `AuthViewModel` restores the session, resolves the user profile state, and handles auth deep links.

## Data And Service Layer

`SupabaseManager` owns the shared `SupabaseClient`, environment-based config, and auth callback parsing.

Feature services under `Core/Supabase` keep network and persistence logic out of the views:

- `AuthService`
- `ProfileService`
- `PromotionService`
- `FitnessService`
- `NutritionService`
- `PayService`
- `TrackerService`
- `PCSService`
- `BenefitsService`
- `NotificationService`
- `NotificationPreferencesService`

This keeps most views focused on presentation and user actions rather than raw Supabase calls.

## State And Models

`Core/Models/Models.swift` defines the shared domain types used across the app, including:

- auth state
- user profile
- promotions, pay, fitness, chow, tracker, PCS, and benefits records
- notification records and preference records
- form draft types used by onboarding and settings flows

## Feature Modules

The app’s major feature areas live under `SquaredAway/Features`:

- `Auth`: login, signup, email verification, splash, password recovery
- `Onboarding`: first-time profile completion
- `Dashboard`: main readiness hub, summaries, and charts
- `Promotions`
- `Fitness`
- `Chow` (implemented by the `Nutrition` feature/views internally)
- `Pay`
- `Tracker`
- `PCS`
- `Benefits`
- `Settings`: profile/security, reminders, notification inbox, diagnostics

Each feature is primarily view-driven, with shared data work delegated to the singleton services above.

## Notifications

There are two notification paths:

- Local device reminders, managed in `Core/Notifications`
- In-app inbox notifications, stored in Supabase and surfaced through `NotificationService`

The app also includes settings and diagnostics for notification permissions, inbox access, preference sync, and end-to-end database pipeline checks.

## Database Shape

The database schema lives in:

- `supabase/migrations/20260323120000_initial_schema.sql`
- `supabase/migrations/20260323153000_feature_modules_and_onboarding_attribution.sql`
- `supabase/migrations/20260323162000_module_notification_triggers_and_profile_attribution_settings.sql`
- `supabase/migrations/20260323170000_chow_branding_copy_updates.sql`
- `supabase_schema.sql`

Key tables include:

- `users_profile`
- `fitness_logs`
- `nutrition_logs`
- `promotions_data`
- `pay_data`
- `tracker_data`
- `pcs_data`
- `benefits_data`
- `notifications`
- `notification_preferences`

The schema also includes row-level security, helper functions, discovery attribution fields on `users_profile`, and triggers for notification generation.

## Design Notes

- Shared styling and reusable UI primitives live under `Core/Utils`
- The app uses a dark visual theme by default
- Charts are used in the dashboard and feature modules for quick trend visibility
- The current architecture favors simple singleton services plus SwiftUI environment/state over heavier dependency injection
