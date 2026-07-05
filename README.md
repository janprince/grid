# GRID — The operating system for your home

GRID is a Ghana-focused home-management app: buy ECG prepaid credit, pay
Ghana Water, renew DStv/GOtv/StarTimes, top up airtime and data, renew
fibre, book vetted home services (plumbing, electrical, AC and more), and
keep every home, meter and receipt organised in one place.

This repository contains the **mobile MVP**: a polished, fully navigable
Flutter app running entirely on local mock data. There are **no live
integrations** — every payment and dispatch is clearly labelled as demo.

## Run it

```bash
flutter pub get
flutter run            # pick an iOS simulator / Android emulator
flutter run -d chrome  # or run in the browser
```

Sign in with any Ghana phone number or email. The demo OTP is **123456**
(shown on the verification screen). Onboarding and the session persist
locally, so the second launch goes straight to the dashboard.

```bash
flutter test      # widget smoke tests incl. the ECG purchase golden path
flutter analyze
```

## Main packages

| Package | Role |
|---|---|
| `flutter_riverpod` | State management (plain `Notifier`s, no codegen) |
| `go_router` | Navigation — `StatefulShellRoute` for the 5 tabs + full-screen flows |
| `shared_preferences` | Persists onboarding completion and the mock session |
| `intl` | GHS currency and date formatting |
| `google_fonts` | Public Sans (headlines) + Inter (body), per the design system |

## Project structure

```
lib/
  main.dart                 # bootstrap: SharedPreferences + ProviderScope
  app/app.dart              # MaterialApp.router + theme
  core/
    theme/                  # design tokens: colors, type scale, spacing, radii
    routing/                # go_router config, route paths, 5-tab shell
    widgets/                # design system: cards, badges, tiles, empty states,
                            # receipts, step-flow scaffold, skeletons, banners
    models/                 # typed domain models (see below)
    data/                   # mock seed data, repository interfaces + mock impls,
                            # SharedPreferences wrapper
    providers/              # Riverpod providers: session, properties, accounts,
                            # transactions, service requests, activity feed
    utils/                  # GHS/date formatters, Ghana-specific validators
  features/
    onboarding/             # splash + 3-page onboarding
    auth/                   # phone/email login, OTP, profile setup (mock)
    home/                   # dashboard: hero status card, quick actions,
                            # reminders, emergency entry, property switcher
    payments/               # pay hub, generic payment flow (all 8 utilities),
                            # success/failed receipts, saved-accounts manager
    services/               # services hub, booking flow, request details
                            # with status timeline
    activity/               # unified history with filters
    properties/             # homes list, details, add/edit
    profile/                # profile + settings subscreens
```

### Domain models

`AppUser`, `Property`, `UtilityAccount`, `PaymentMethod`, `UtilityPlan`,
`PaymentTransaction`, `ServiceCategory`, `ServiceRequest`,
`ServiceProviderSummary`, `Reminder`, `ActivityItem` — all in
`lib/core/models/`. `UtilityType` is an enhanced enum whose metadata
(labels, icons, validation rules, quick amounts, plan-based vs
amount-based) drives the single generic payment flow for all eight
utility types.

## What is mocked

- **Authentication** — `MockAuthApi`: any valid phone/email works, OTP is
  `123456`, session is stored on-device only.
- **Payments** — `MockPaymentsApi`: simulated latency, generated
  transaction references and ECG token placeholders. The "Demo Declined
  Card" payment method deterministically fails so the failure UX can be
  exercised. No money moves anywhere.
- **Service dispatch** — `MockServicesApi`: requests are created locally
  in the *Pending* state; seeded requests demonstrate assigned,
  in-progress, completed and cancelled states.
- **Seed data** — `lib/core/data/mock_data.dart`: Kwame Mensah, three
  homes (East Legon, Kumasi, Spintex), saved meters/smartcards/numbers,
  reminders and a realistic payment history. Dates are computed relative
  to "now" so labels like "Due tomorrow" stay believable.

## Where live APIs plug in later

The app only talks to three interfaces in
`lib/core/data/repositories.dart`:

- `AuthApi` → real OTP delivery + identity service
- `PaymentsApi` → utility biller aggregator / payment processor
- `ServicesApi` → provider dispatch backend

Swap the `Mock*` implementations behind `authApiProvider`,
`paymentsApiProvider` and `servicesApiProvider`
(`lib/core/providers/app_providers.dart`) for HTTP clients, and replace
the notifier seed data with repository fetches. Screens and flows need no
changes. Catalog data (TV bouquets, data bundles, fibre plans) currently
comes from `CatalogRepository` and would move server-side the same way.

## Design system

Adopted from the GRID Stitch design project ("Premium Utility"):

- **Colors** — forest green `#003527` / `#064E3B` primary, teal `#006A61`
  secondary, off-white `#F8FAF6` surfaces, white cards, semantic
  success/warning/danger tints. Tokens in `core/theme/app_colors.dart`.
- **Type** — Public Sans for headlines, Inter for body and labels.
- **Shape** — 24px radius cards, 12–16px inputs/buttons, pill chips.
- **Depth** — soft green-tinted ambient shadows, no hard borders.

All spacing, radii and gaps come from `core/theme/app_spacing.dart` —
avoid hardcoded values in screens.
