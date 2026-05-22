# Where The Vibes At

**wherethevibesat** — social nightlife discovery: find venues, check in, earn rank, and share the vibe.

Built with Flutter from the Tendi hi-fidelity Figma prototype. Dart package: `wherethevibesat`. Bundle ID: `com.wherethevibesat`.

## Quick start

```bash
flutter pub get
flutter run
```

After structural changes, use a **hot restart** (`R`), not hot reload.

If you changed the app ID or package name, stop the running app and run `flutter clean && flutter run` once.

## Dev login (no Supabase required)

`lib/config/dev_auth_config.dart` sets `useDummyAuth = true` by default. Supabase is skipped on startup.

| Email | Password | Role |
|-------|----------|------|
| `customer@demo.com` | `password` | Customer |
| `admin@demo.com` | `password` | Admin (admin dashboard in Profile / Settings) |
| `owner@demo.com` | `password` | Venue owner / promoter |

Any email with password **6+ characters** also works for register/login in dummy mode.

To use real Supabase auth, set `useDummyAuth = false` and configure keys per [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

## App flow

```
Splash → Welcome (first launch) → Login / Register → App shell
```

**Bottom nav:** Discover · Ranking · Check-in (FAB) · Profile · More

## Project layout

```
lib/
  config/          # Brand, dev auth, Supabase
  data/            # Mock discover, ranking, venues, messages, etc.
  models/          # User, venue, leaderboard
  screens/
    wtva/          # Main consumer UI
    admin/         # Admin dashboard (legacy backend tooling)
  services/        # Auth, user, Stripe
  theme/           # figma_theme.dart (WTVA design tokens)
  widgets/wtva/    # Reusable WTVA components
```

## Docs

- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) — product scope and features
- [SUPABASE_SETUP.md](SUPABASE_SETUP.md) — database and auth
- [STRIPE_SETUP.md](STRIPE_SETUP.md) — Stripe keys and Connect (admin)

## Design

- Theme: Urbanist via `google_fonts`, dark UI (`WtvaTheme.dark`)
- Figma source: Tendi Hi-Fidelity (`Ys0LgUXD3KQpjtJ0VVTsKe`)
