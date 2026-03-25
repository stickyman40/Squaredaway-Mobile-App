# Feature Overview

This page maps the major app features to their main screens, services, and data sources.

## Authentication

- Views:
  `SplashView`, `LoginView`, `SignupView`, `EmailVerificationView`, `PasswordRecoveryView`
- State owner:
  `AuthViewModel`
- Services:
  `AuthService`, `ProfileService`, `SupabaseManager`
- Related data:
  `auth.users`, `users_profile`

This area handles sign-in, sign-up, email verification, session restore, password reset, and password recovery deep links.

## Onboarding

- View:
  `OnboardingView`
- State owner:
  `AuthViewModel`
- Services:
  `ProfileService`
- Related data:
  `users_profile`

This area completes the user profile and sets the onboarding completion state used to unlock the dashboard.

## Dashboard

- View:
  `DashboardView`
- Services:
  `PromotionService`, `FitnessService`, `NutritionService`, `PayService`, `TrackerService`, `PCSService`, `BenefitsService`, `NotificationService`
- Related data:
  `promotions_data`, `fitness_logs`, `nutrition_logs`, `pay_data`, `tracker_data`, `pcs_data`, `benefits_data`, `notifications`

This is the main readiness hub. It aggregates summaries, unread inbox count, readiness scoring, acquisition details, and chart data from multiple feature services.

## Promotions

- View:
  `PromotionsView`
- Service:
  `PromotionService`
- Related data:
  `promotions_data`

This area tracks promotion readiness details such as current rank, target rank, points, and board date.

## Fitness

- View:
  `FitnessView`
- Service:
  `FitnessService`
- Related data:
  `fitness_logs`

This area manages workout history, durations, optional scores, and trend data.

## Chow

- View:
  `NutritionView`
- Service:
  `NutritionService`
- Related data:
  `nutrition_logs`

This area stores meals, calories, macros, chow reminders, and trend data.

## Pay

- View:
  `PayView`
- Service:
  `PayService`
- Related data:
  `pay_data`

This area stores pay-grade information and monthly compensation components.

## Tracker

- View:
  `TrackerView`
- Service:
  `TrackerService`
- Related data:
  `tracker_data`

This area tracks assignment details like current duty station, duty status, next milestone, and optional report date.

## PCS

- View:
  `PCSView`
- Service:
  `PCSService`
- Related data:
  `pcs_data`

This area tracks PCS planning details such as origin, destination, move date, and major travel/logistics checkpoints.

## Benefits

- View:
  `BenefitsView`
- Service:
  `BenefitsService`
- Related data:
  `benefits_data`

This area tracks benefits readiness across health, education, retirement, and family support planning.

## Settings

- Views:
  `AppSettingsView`, `ReminderSettingsView`, `NotificationsView`
- Services:
  `NotificationService`, `NotificationPreferencesService`, `ProfileService`, `AuthService`
- Local helpers:
  `ReminderService`, `ReminderPreferences`, `NotificationPreferences`
- Related data:
  `users_profile`, `notifications`, `notification_preferences`

This area owns profile editing, discovery-source attribution updates, security actions, reminder settings, inbox access, preference sync, and database notification diagnostics.

## Cross-Cutting Features

### In-App Notifications

- Primary service:
  `NotificationService`
- Related data:
  `notifications`, `notification_preferences`

This area supports fetch, read/delete actions, sample inserts, bulk clear, unread counts, and database pipeline probing.

### Local Reminders

- Primary helpers:
  `ReminderService`, `ReminderPreferences`
- Platform dependency:
  `UserNotifications`

This area is device-specific and separate from the Supabase inbox notification system.

### Shared Models And Styling

- Models:
  `Core/Models/Models.swift`
- UI/theme:
  `Core/Utils`

These provide the shared domain types, form drafts, theme constants, and reusable UI components used across all features.
