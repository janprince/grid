# GRID — The operating system for your home

GRID is a Ghana-focused home-management app: buy ECG prepaid credit, pay
Ghana Water, renew DStv/GOtv/StarTimes, top up airtime and data, renew
fibre, book vetted home cleaning and laundry, and
keep every home, meter and receipt organised in one place.

This repository contains the **mobile MVP**. Sign-in, the profile, homes
and saved utility accounts run against the GRID API (`../Grid.API`).
Payments and service bookings are still simulated on local mock data and
clearly labelled as demo.

## Run it

Start the API first (see [`../Grid.API/README.md`](../Grid.API/README.md)):

```bash
dotnet run --project ../Grid.API/src/Grid.Api   # http://localhost:8080
```

```bash
flutter pub get
flutter run            # pick an iOS simulator / Android emulator
```

Sign in with any Ghana mobile number. A development API accepts the OTP
**123456** and the verification screen shows it. A new number goes through
profile setup (first name required; last name and email optional). Tokens
live in platform secure storage, so the next launch goes straight to the
dashboard.

- **Base URL.** It defaults to `http://10.0.2.2:8080/api/v1` on the Android
  emulator and `http://127.0.0.1:8080/api/v1` elsewhere. On a physical device,
  override it with `--dart-define=GRID_API_BASE_URL=http://<your-ip>:8080/api/v1`.
- **Offline demo.** `--dart-define=GRID_USE_API=false` runs everything on mock
  data, with Kwame Mensah's seeded homes and accounts.
- **Web.** The browser build only works in mock mode, because the API sends
  no CORS headers.

```bash
flutter test      # widget smoke tests incl. the ECG purchase golden path
flutter analyze
```

## Main packages

| Package | Role |
|---|---|
| `flutter_riverpod` | State management (plain `Notifier`s, no codegen) |
| `go_router` | Navigation — `StatefulShellRoute` for the 5 tabs + full-screen flows |
| `dio` | HTTP client for the GRID API (`core/data/api/api_client.dart`) |
| `flutter_secure_storage` | Access and refresh tokens |
| `shared_preferences` | Persists onboarding completion and the demo-mode session |
| `intl` | GHS currency and date formatting |

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
    data/                   # repository interfaces + mock impls, mock seed
                            # data, SharedPreferences wrapper
      api/                  # GRID API client (envelope, 401 refresh,
                            # X-Grid-App), secure session store, live repos
    providers/              # Riverpod providers: session, properties, accounts,
                            # transactions, service requests, activity feed
    utils/                  # GHS/date formatters, Ghana-specific validators
  features/
    onboarding/             # splash + 3-page onboarding
    auth/                   # phone login, OTP, profile setup
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

## What talks to the API

`AuthApi`, `PropertiesApi` and `UtilityAccountsApi` have live
implementations in `lib/core/data/api/live_repositories.dart`, selected by
`apiEnabledProvider`. The client contract they follow is
[`../DOCUMENTATION/api-integration.md`](../DOCUMENTATION/api-integration.md).

- The server owns `isPrimary` and `isDefault`. Every change is followed by
  a reload, because the server moves defaults and unlinks accounts as side
  effects.
- Enums go over the wire in PascalCase (`Ecg`, `DataBundle`, `Apartment`).
- Refresh tokens rotate, so `ApiClient` collapses concurrent 401s onto one
  refresh and then replays the failed requests.

## What is mocked

- **Authentication in demo mode** — `MockAuthApi`: any valid phone works,
  the OTP is `123456`, and the session is stored in SharedPreferences.
- **Homes and saved accounts in demo mode** — `MockHomeStore`, which
  follows the server's rules (first home is primary, one default per
  utility).
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

Payments and services still sit behind mock-only interfaces in
`lib/core/data/repositories.dart`:

- `PaymentsApi` → utility biller aggregator / payment processor
- `ServicesApi` → provider dispatch backend

Give each a live implementation next to the others in `core/data/api/`,
and choose it in `paymentsApiProvider` / `servicesApiProvider` the way
`propertiesApiProvider` does. Screens and flows need no
changes. Catalog data (TV bouquets, data bundles, fibre plans) currently
comes from `CatalogRepository` and would move server-side the same way.

## Design system

GRID shares its design system with GRID Pro — navy actions, white flat
surfaces, Plus Jakarta Sans, one tint per service (mint for cleaning, sky for
laundry), uppercase button labels. The full reference — tokens, components,
screen templates, writing and accessibility rules — is
[`../DOCUMENTATION/design-system.md`](../DOCUMENTATION/design-system.md).

- **Tokens** — `core/theme/app_colors.dart`, `app_theme.dart` (`AppText`),
  `app_spacing.dart`, `service_art.dart` (service tints).
- **Shared components** — `core/widgets/system.dart` (`PrimaryButton`,
  `AppHeader`, `NavyPanel`, `TintCard`, `DetailGroup`, `MenuGroup`,
  `showConfirmationSheet`, …) and `service_widgets.dart`, named as in GRID Pro.
- **Services** — v1 books two: home cleaning and laundry
  (`core/models/service_category.dart`). The emergency call-out flow was
  removed with the trade categories.

All spacing, radii and gaps come from `core/theme/app_spacing.dart` —
avoid hardcoded values in screens.
