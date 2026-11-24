# GRID — The operating system for your home

GRID is a Ghana-focused home-management app: buy ECG prepaid credit, pay
Ghana Water, renew DStv/GOtv/StarTimes, top up airtime and data, renew
fibre, book vetted home cleaning, laundry, AC servicing and pest control at
GRID's fixed prices, and keep every home, meter and receipt organised in one
place.

This repository contains the **mobile MVP**. Sign-in, the profile, homes
and saved utility accounts run against the GRID API (`../Grid.API`).
Bill payments and service booking are live through the GRID API: the customer
picks packages at GRID's prices, pays by Mobile Money at booking, follows the
professional GRID assigns, confirms the job and rates it.

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
| `shared_preferences` | Persists onboarding completion |
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
    data/                   # repository interfaces and the live API client
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

`AuthApi`, `PropertiesApi`, `UtilityAccountsApi`, `BillPaymentsApi` and `ServicesApi` have
live implementations in `lib/core/data/api/live_repositories.dart`. The client
contract they follow is
[`../DOCUMENTATION/api-integration.md`](../DOCUMENTATION/api-integration.md).

- The server owns `isPrimary` and `isDefault`. Every change is followed by
  a reload, because the server moves defaults and unlinks accounts as side
  effects.
- Enums go over the wire in PascalCase (`Ecg`, `DataBundle`, `Apartment`).
- Refresh tokens rotate, so `ApiClient` collapses concurrent 401s onto one
  refresh and then replays the failed requests.

Services come from `GET /service-catalogue`; the app holds no service list of
its own. `core/theme/service_art.dart` adds only how each slug looks (tint,
render, fallback glyph). How booking and payment work on the server is in
[`../Grid.API/docs/marketplace.md`](../Grid.API/docs/marketplace.md).

## Not built yet

Reminders are empty: nothing on the server produces them yet. Plumbing and
electrical (quoted on site) arrive once the API launches them; the app shows
whatever the catalogue lists. The widget tests run on in-memory fakes in
`test/support/fakes.dart`.

## Design system

GRID shares its design system with GRID Pro — navy actions, white flat
surfaces, Plus Jakarta Sans, one tint per service (mint for cleaning, sky for
laundry, violet for AC servicing, olive for pest control), sentence-case
buttons. A service is shown as a 3D render on its tint
(`assets/images/services/3d/<slug>.png`), falling back to its older icon and
then a glyph. The full reference — tokens, components,
screen templates, writing and accessibility rules — is
[`../DOCUMENTATION/design-system.md`](../DOCUMENTATION/design-system.md).

- **Tokens** — `core/theme/app_colors.dart`, `app_theme.dart` (`AppText`),
  `app_spacing.dart`, `service_art.dart` (service tints and artwork by slug).
- **Shared components** — `core/widgets/system.dart` (`PrimaryButton`,
  `AppHeader`, `NavyPanel`, `TintCard`, `DetailGroup`, `MenuGroup`,
  `showConfirmationSheet`, …) and `service_widgets.dart`, named as in GRID Pro.
- **Services** — whatever `/service-catalogue` lists
  (`core/models/service_catalogue.dart`): at launch home cleaning, laundry,
  AC servicing and pest control. Screens are in `features/services/`
  (hub, service page, booking flow, booking details).

All spacing, radii and gaps come from `core/theme/app_spacing.dart` —
avoid hardcoded values in screens.
