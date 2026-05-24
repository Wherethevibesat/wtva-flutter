# Where The Vibes At (WTVA) — Web Platform Build Instructions

**Audience:** Cursor agents, contractors, and internal developers building the WTVA **web platform** (customer web, business web, and operations admin).

**Source of truth:** This document is derived from the Flutter monorepo at `c:\src\thisishtx` (package `wherethevibesat`, GitHub `Wherethevibesat/wtva-flutter`). Treat the mobile app as the **product specification**; the web stack is **new work** that must reach parity where noted and replace mock-only admin flows with production APIs.

**Related docs:** [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) · [README.md](README.md) · [SUPABASE_SETUP.md](SUPABASE_SETUP.md) · [STRIPE_SETUP.md](STRIPE_SETUP.md)

---

## Table of contents

1. [Product overview](#1-product-overview)
2. [What exists today](#2-what-exists-today)
3. [Web platform scope](#3-web-platform-scope)
4. [Recommended tech stack](#4-recommended-tech-stack)
5. [Design system](#5-design-system)
6. [Authentication and roles](#6-authentication-and-roles)
7. [Data model and API contract](#7-data-model-and-api-contract)
8. [Customer web application](#8-customer-web-application)
9. [Business web application](#9-business-web-application)
10. [Admin portal (full specification)](#10-admin-portal-full-specification)
11. [Backend extensions required](#11-backend-extensions-required)
12. [Security and compliance](#12-security-and-compliance)
13. [Repository layout (proposed)](#13-repository-layout-proposed)
14. [Environment and deployment](#14-environment-and-deployment)
15. [Implementation phases](#15-implementation-phases)
16. [Flutter reference map](#16-flutter-reference-map)
17. [Acceptance criteria checklist](#17-acceptance-criteria-checklist)

---

## 1. Product overview

**Where The Vibes At** (WTVA) is a social nightlife discovery platform. Users discover venues, check in, earn rank/points, and connect socially. Venue owners run promotions, browse high-rank customers (“talent”), and book paid appearances. Platform operators use an **admin portal** to moderate content, manage users and venues, handle payouts, and configure platform settings.

| Brand | Value |
|-------|--------|
| Display name | Where The Vibes At |
| Slug / package | `wherethevibesat` |
| Short name | `wtva` |
| Tagline | Find where the vibes at tonight |
| Bundle ID (mobile) | `com.wherethevibesat` |

**Core product loop**

1. Customer discovers venue (feed, map, search).
2. Customer checks in → earns points (default **+25** per check-in).
3. Points unlock rank tiers → businesses can invite/book high-rank users.
4. Business creates promotions and talent bookings.
5. Admin moderates submissions, verification, featured content, and platform revenue.

**Positioning:** National nightlife app (not Houston-only in brand copy), though seed data and filters often default to Houston.

---

## 2. What exists today

| Layer | Status | Location |
|-------|--------|----------|
| Flutter mobile app (customer + business + embedded admin) | **Built** (UI complete; many features mock-backed) | `lib/screens/wtva/`, `lib/screens/business/`, `lib/screens/admin/` |
| Supabase schema (core tables + RLS) | **Deployed-capable** | `supabase/migrations/000_full_database.sql`, `003_business_verification.sql` |
| Dedicated web admin SPA | **Does not exist** | — |
| Customer/business web apps | **Does not exist** (only default Flutter `web/` scaffold) | `web/index.html` |
| Supabase Edge Functions | **Documented only** | `STRIPE_SETUP.md` |
| Events, VIP packages, submissions, Stripe keys tables | **Mock in app only** | Admin screens under `lib/screens/admin/` |

**Data integration today**

- When `USE_SUPABASE_DATA=true` and `USE_DUMMY_AUTH=false`, repositories sync: venues, check-ins, favorites, rankings, business venue profile, promotions, talent bookings, verification uploads.
- Social (messages, chat, notifications, live stories), admin dashboard stats, events, VIP packages, earnings — **mock stores** in `lib/data/mock_*.dart`.

---

## 3. Web platform scope

Build **three authenticated web applications** sharing one Supabase project and design system:

| App | URL pattern (example) | Primary users | Role gate |
|-----|----------------------|---------------|-----------|
| **Customer web** | `app.wherethevibesat.com` | Nightlife consumers | `customer` (and optionally guest browse) |
| **Business web** | `business.wherethevibesat.com` | Venue owners / promoters | `venueOwner` |
| **Admin portal** | `admin.wherethevibesat.com` | WTVA operations team | `admin` |

**Out of scope for v1 web (unless explicitly prioritized):** native-only features (push notifications via FCM, deep links to Stripe Connect on mobile), real live streaming, GPS-verified check-in. Plan API hooks so mobile can adopt the same backend later.

**Parity rule:** Any screen in `lib/screens/admin/` must have a **production-backed** equivalent in the admin portal—not mock JSON. Customer/business web should match Flutter flows in `lib/screens/wtva/` and `lib/screens/business/` unless responsive layout requires simplification.

---

## 4. Recommended tech stack

Use a stack that matches Supabase-first architecture and allows fast iteration in Cursor.

### 4.1 Frontend (recommended)

| Choice | Recommendation | Rationale |
|--------|----------------|-----------|
| Framework | **Next.js 15+** (App Router) | SSR for marketing pages; client components for maps/dashboards; strong Supabase ecosystem |
| Language | **TypeScript** | Shared types with API routes |
| Styling | **Tailwind CSS** | Port tokens from `lib/theme/figma_theme.dart` |
| UI primitives | **shadcn/ui** or Radix | Accessible admin tables, dialogs, forms |
| Maps | **Mapbox GL JS** or **Leaflet** | Parity with Flutter `flutter_map` / `latlong2` |
| State | React Query (TanStack Query) + Supabase client | Server state for venues, check-ins, admin lists |
| Auth | `@supabase/ssr` | Cookie-based sessions for web; role checks server-side |

**Alternative:** Flutter Web for a single codebase—acceptable for customer app only; **not recommended for admin** (service-role patterns, tables, Stripe secrets are awkward in Flutter client).

### 4.2 Backend

| Service | Use |
|---------|-----|
| **Supabase Auth** | Email/password, OAuth (Google/Apple as needed), password reset |
| **Supabase Postgres** | Primary database (existing migrations) |
| **Supabase Storage** | Profile images, check-in media, `business-verification` docs |
| **Supabase Realtime** | Optional: live check-in feed, booking status |
| **Supabase Edge Functions** | Stripe, webhooks, admin-only mutations, signed URLs for verification docs |
| **Stripe** | Platform payouts, submission fees (admin); Connect/transfers per `STRIPE_SETUP.md` |

### 4.3 Monorepo option

Either:

- **A)** New folder in this repo: `apps/web-customer`, `apps/web-business`, `apps/web-admin`, `packages/shared-types`
- **B)** Separate repo `wtva-web` linked to same Supabase project

Default recommendation: **A** in `thisishtx` for shared migration visibility.

### 4.4 Versions aligned with mobile

| Dependency | Mobile reference |
|------------|------------------|
| Dart SDK | `^3.9.2` (`pubspec.yaml`) |
| Flutter | `>=3.38.0` (lockfile) |
| Supabase client | `supabase_flutter ^2.12.0` → use `@supabase/supabase-js` latest stable |
| Supabase project ref | `wabtknktqnrxnffkgpzh` (`supabase/config.toml`) |

---

## 5. Design system

Port the mobile **monochrome nightlife** theme from `lib/theme/figma_theme.dart`.

### 5.1 Colors (CSS variables)

```css
:root {
  --wtva-black: #000000;
  --wtva-dark-400: #121212;
  --wtva-dark-300: #1c1c1c;
  --wtva-card: #141414;
  --wtva-neutral-50: #ffffff;
  --wtva-neutral-100: #f4f4f5;
  --wtva-neutral-200: #a1a1aa;
  --wtva-neutral-300: #71717a;
  --wtva-on-primary: #000000;
}
```

Rank tier cards use gray gradients (`rankBlueGradient`, `rankPinkGradient`, etc.)—see `WtvaColors` in Flutter theme.

### 5.2 Typography

- **Font:** Urbanist (Google Fonts) — same as mobile `google_fonts`.
- **Weights:** 400 body, 600–700 headings.

### 5.3 Layout

- Mobile-first breakpoints; admin uses **desktop-first** (min width 1024px) with collapsible sidebar.
- Consumer max content width ~480px centered on large screens (optional) to mirror 375×812 Figma patterns.
- Figma reference file: **Tendi Hi-Fidelity** (`Ys0LgUXD3KQpjtJ0VVTsKe`).

### 5.4 Components to implement

| Component | Flutter reference |
|-----------|-------------------|
| Bottom nav (customer) | `lib/widgets/wtva/wtva_bottom_nav.dart` |
| Venue card | `lib/widgets/wtva/wtva_promoted_card.dart`, discover list |
| Rank progress | `lib/widgets/wtva/wtva_rank_progress.dart` |
| Map view | `lib/widgets/wtva/wtva_map_view.dart` |
| Business shell nav | `lib/screens/business/business_shell.dart` |

---

## 6. Authentication and roles

### 6.1 Roles (`public.users.role`)

| DB value | Display | Access |
|----------|---------|--------|
| `customer` | Customer | Customer web + mobile consumer features |
| `venueOwner` | Venue owner / promoter | Business web + business mobile shell |
| `admin` | Admin | Admin portal only |

Role is set at signup via `raw_user_meta_data.role` and trigger `handle_new_user()` (see migration).

### 6.2 Web auth flows

Implement for **each** web app:

1. **Login** — email + password via Supabase Auth.
2. **Register** — collect name, email, password; set role in metadata (`customer` or `venueOwner` only from public signup; `admin` created manually or invite-only).
3. **Forgot password** — Supabase reset email; redirect to web app `/auth/reset`.
4. **Session** — HTTP-only cookies via `@supabase/ssr`; middleware checks session on protected routes.
5. **Role guard** — middleware redirects wrong role (e.g. customer hitting `/admin` → 403 or redirect to customer app).

### 6.3 Admin access

- Never rely on client-only role checks for mutations.
- Admin API routes and Edge Functions use **`SUPABASE_SERVICE_ROLE_KEY`** server-side only.
- Create admin users by updating `public.users.role = 'admin'` after Auth signup, or use Supabase dashboard.

### 6.4 Business verification

Flow exists on mobile (`BusinessVerificationService`):

1. Owner uploads PDF/image to bucket `business-verification` at path `{user_id}/{filename}`.
2. Venue columns: `verification_document_path`, `verification_status` ∈ `none | pending | approved | rejected`.
3. **Admin portal must review** pending docs (requires new storage policy or signed URLs via Edge Function—see [§11](#11-backend-extensions-required)).

### 6.5 Dev / demo accounts

From `lib/config/dev_auth_config.dart` (for local Supabase seeding):

| Email | Password | Role |
|-------|----------|------|
| `customer@demo.com` | `password` | customer |
| `business@demo.com`, `owner@demo.com` | `password` | venueOwner |
| `admin@demo.com` | `password` | admin |

Mobile dummy auth: `--dart-define=USE_DUMMY_AUTH=true`. Web should **never** use dummy auth in production.

---

## 7. Data model and API contract

### 7.1 Existing tables (production)

Apply migrations in order:

1. `supabase/migrations/000_full_database.sql`
2. `supabase/migrations/003_business_verification.sql`

| Table | Purpose |
|-------|---------|
| `public.users` | Profile linked to `auth.users`; role, metadata |
| `public.user_rankings` | `total_points` per user |
| `public.venues` | Venue catalog; `owner_id`, `subscription_tier`, `verified`, geo, hours |
| `public.check_ins` | User check-ins; `points_awarded` (default 25) |
| `public.user_favorites` | Saved venues |
| `public.venue_promotions` | Business promos; status `draft \| scheduled \| live \| ended` |
| `public.talent_bookings` | Paid invites; status `pending \| confirmed \| checkedIn \| completed \| cancelled` |

**Storage bucket:** `business-verification` (private, 10MB, pdf/jpeg/png/webp).

### 7.2 Ranking rules (business logic)

Implement in shared config (mirror `lib/data/ranking_rules.dart`):

| Action | Points |
|--------|--------|
| Check-in | +25 |
| Check-in with post | +25 |
| Hourly stay | +10 |
| Business invite accepted | +50 |

**Rank tiers**

| Tier | Points required | Notes |
|------|-----------------|-------|
| Vibee | 500 | Businesses cannot contact yet |
| Vibe Master | 10,000 | Paid invites; ~$50/hr reference rate in copy |
| Vibe Champion | 25,000 | ~$100/hr |
| Vibesetters | 50,000 | ~$200/hr |
| Influencers | 100,000 | ~$500/hr |

### 7.3 Repository pattern (mobile → web)

Map Flutter services to web data layer:

| Flutter service | Web module |
|-----------------|------------|
| `auth_service.dart` | `lib/auth` + Supabase client |
| `venue_repository.dart` | `api/venues` |
| `check_in_repository.dart` | `api/check-ins` |
| `ranking_repository.dart` | `api/rankings` |
| `favorites_service.dart` | `api/favorites` |
| `business_repository.dart` | `api/business` |
| `business_verification_service.dart` | `api/verification` + Storage |

---

## 8. Customer web application

**Reference:** `lib/screens/wtva/` (43 files), shell in `app_shell.dart`.

### 8.1 Information architecture

```
/                          → Discover (or redirect to /discover if authed)
/discover                  → Main feed
/discover/search           → Search venues
/discover/map              → Map search
/discover/events           → Events list (?type= optional)
/discover/neighborhoods/:slug → Venues/events by neighborhood
/venues/:id                → Venue detail
/ranking                   → Leaderboards + my rank
/check-in                  → Check-in flow (modal or dedicated route)
/check-in/history          → Past check-ins
/messages                  → Messages list (v2 if not mock-backed)
/messages/:threadId        → Conversation (v2)
/photos                    → Media hub (v2)
/notifications             → Notification center (v2)
/profile                   → Own profile
/profile/edit              → Edit profile
/profile/favorites         → Saved venues
/settings                  → Account settings
/help                      → Help & support
/auth/login | register | forgot-password | terms
```

### 8.2 Feature specification

| Feature | Description | Data source v1 | Flutter reference |
|---------|-------------|----------------|-------------------|
| Onboarding | Splash, welcome slides (first visit), terms acceptance | localStorage flag | `welcome_screen.dart`, `wtva_terms_screen.dart` |
| Discover feed | Categories, promoted card, venue cards, live stories strip | Venues table + mock stories until `stories` table | `discover_screen.dart` |
| Discover filter UX | **One** venue category chip row; Events/Areas/Map shortcuts; Browse sheet for event types + neighborhoods (not three chip rows on feed) | **[docs/DISCOVER_FILTER_UX_WEB.md](docs/DISCOVER_FILTER_UX_WEB.md)** §3–5 | `discover_screen.dart`, `discover_quick_browse.dart`, `discover_browse_sheet.dart` |
| Events filter UX | Search on page; **Filters** modal (event type, day of week, neighborhood); URL `?type=&day=&neighborhood=` | **[docs/DISCOVER_FILTER_UX_WEB.md](docs/DISCOVER_FILTER_UX_WEB.md)** §6–10 | `events_browse_screen.dart`, `events_filters_sheet.dart`, `weekdays.dart` |
| Search | Text search, filters | Venues query | `search_screen.dart` |
| Map search | Map pins, neighborhood filter | Venues lat/lng | `map_search_screen.dart`, `city_picker_sheet.dart` |
| Venue detail | Hero, tabs, recent check-ins, directions, call, check-in CTA | Venues + check_ins | `venue_detail_screen.dart` |
| Check-in FAB flow | Pick venue → options → create post → active check-in | check_ins insert | `check_in_sheet.dart`, `check_in/*` |
| Go live | Mock stream UI | v2 | `go_live_screen.dart` |
| Ranking | Global + follower boards, tier progress, points info sheet | user_rankings | `ranking_screen.dart`, `points_info_sheet.dart` |
| Favorites | Toggle favorite venues | user_favorites | `wtva_favorites_screen.dart` |
| Profile | Avatar, name, stats, check-in history link | users | `wtva_profile_screen.dart` |
| Guest browse | Read-only discover; gate actions | AccountGate pattern | `lib/utils/account_gate.dart` |
| Promoter tools | Customer with promoter extras | v2 / role flag | `promoter_tools_screen.dart` |

### 8.3 Guest vs authenticated gates

Replicate `AccountGate` behavior: guests can browse; check-in, favorites, messages, and profile edit require sign-in. Show modal or redirect to `/auth/login`.

### 8.4 Responsive behavior

- **Mobile web:** bottom navigation (5 tabs: Discover, Ranking, Check-in center FAB, Messages, More).
- **Desktop:** left sidebar or top nav; check-in as prominent button.

---

## 9. Business web application

**Reference:** `lib/screens/business/` (17 files), shell in `business_shell.dart`.

### 9.1 Information architecture

```
/                          → Business home dashboard
/browse                    → Browse customers/talent
/browse/:userId            → Talent profile + book CTA
/bookings                  → Booking list
/bookings/:id              → Booking detail / status updates
/promotions                → Promo list
/promotions/new | :id/edit → CRUD
/analytics                 → Metrics (charts)
/payments                  → Payout settings
/settings                  → Venue profile, account, subscription
/auth/login | register | forgot-password
/onboarding                → Multi-step registration + verification upload
```

### 9.2 Feature specification

| Feature | Description | Data source | Flutter reference |
|---------|-------------|-------------|-------------------|
| Registration (9 steps) | Business info, venue link, subscription tier, doc upload | Auth + venues + storage | `business_registration_flow.dart` |
| Subscription tiers | Silver $49, Gold $99, Platinum $199/mo | `venues.subscription_tier` | `business_subscription_screen.dart` |
| Home dashboard | Ad metrics, check-ins preview, promo summary | venues, check_ins, promotions | `business_home_screen.dart` |
| Browse talent | Filter by rank, location, age, gender; sort by rank | users + user_rankings (RLS: owners read customers) | `business_browse_flow.dart` |
| Book talent | Create booking, amount, event time, note | talent_bookings | `business_booking_flow.dart` |
| Bookings management | List/filter; status transitions | talent_bookings | `business_bookings_flow.dart` |
| Promotions CRUD | draft → scheduled → live → ended | venue_promotions | `business_promotions_flow.dart` |
| Analytics | Views, check-ins, promo performance | aggregate queries / v2 | `business_analytics_flow.dart` |
| Payments | Payout method display | venues.payout_method + Stripe v2 | `business_payments_flow.dart` |
| Settings | Profile, switch to customer mode link | users, venues | `business_settings_flow.dart` |
| Verification | Upload license; status pending | storage + venues.verification_* | `business_verification_service.dart` |

### 9.3 Business auth gate

Only `venueOwner` role may access business routes. Others redirect to customer app or show “Apply for business account.”

---

## 10. Admin portal (full specification)

**Reference:** `lib/screens/admin/` (14 screens). Today **all dashboard metrics and several modules use mock data**—the web admin must implement real Supabase + Edge Function backends.

### 10.1 Admin information architecture

```
/                              → Dashboard (KPIs + quick links)
/venues                        → Venue list
/venues/new                    → Create venue
/venues/:id/edit               → Edit venue (all fields + featured flag)
/events                        → Event list
/events/new | /events/:id/edit → Event CRUD
/users                         → User list + role management
/submissions                   → Pending venues & events (tabs)
/submissions/verification      → Business doc review queue
/vip-packages                  → VIP package catalog
/vip-packages/new | :id/edit   → VIP CRUD
/earnings                      → Revenue dashboard
/earnings/withdraw             → Initiate platform withdrawal
/earnings/transactions         → Transaction log
/settings                      → Platform settings
/settings/stripe/keys          → Stripe API keys (server-side only in prod)
/settings/stripe/accounts      → Connected accounts list
/notifications                 → Admin alerts (v2)
/auth/login                    → Admin-only login
```

### 10.2 Dashboard (`admin_dashboard_screen.dart`)

**Purpose:** Operations home with at-a-glance KPIs and navigation cards.

**KPIs to compute from database (replace mock stats):**

| Metric | Query hint |
|--------|------------|
| Total venues | `COUNT(*) FROM venues` |
| Total events | `COUNT(*) FROM events` (after migration) |
| Pending submissions | venues/events with `status = 'pending_review'` + `verification_status = 'pending'` |
| Total users | `COUNT(*) FROM users` by role breakdown |
| Featured venues | `venues.featured = true` (add column) |
| Featured events | `events.featured = true` (add column) |
| Total earnings | Sum `platform_transactions.amount` |
| Pending payments | Count `platform_transactions.status = 'pending'` |

**Quick actions (navigation):** Venues, Events, Users, Pending Submissions, VIP Packages, Earnings, Settings.

**UI:** Welcome card with admin name from `users.name`; stat cards tappable to drill down; notification icon (future).

### 10.3 Venues management (`admin_venues_screen.dart`, `admin_edit_venue_screen.dart`)

**List view**

- Search by name, neighborhood, type.
- Filters: verified, subscription tier, featured, verification status.
- Columns: name, type, owner, rating, check-in count, tier, verified badge, actions (edit, feature, deactivate).

**Create / edit venue**

Fields aligned with `public.venues`:

- `id` (slug/text PK), `name`, `venue_type`, `address`, `description`
- Media: `image_url`, `logo_url`
- Ratings display: `rating`, `full_stars`, `half_star`
- Location: `latitude`, `longitude`, `distance_miles` (computed client-side optional)
- Operations: `is_open`, `hours_label`, `phone`, `services` (JSON array), `categories` (JSON array)
- Business: `owner_id`, `subscription_tier`, `verified`, `payout_method`
- Verification: `verification_status`, view/download document (admin only)
- Admin-only: `featured` boolean, `published` boolean (if using submission workflow)

**Actions**

- Assign / change `owner_id` (link to user search).
- Approve/reject verification (sets `verification_status`, optional email to owner).
- Feature/unfeature on discover.
- Delete venue (soft-delete preferred: `deleted_at`).

### 10.4 Events management (`admin_events_screen.dart`, `admin_edit_event_screen.dart`)

**Status today:** Mock only in Flutter. **Must add `events` table** (see §11).

**List view**

- Search by title, venue, neighborhood, date range.
- Filters: event type, featured, status (draft, published, cancelled).

**Create / edit event**

Suggested fields:

- `id`, `venue_id`, `title`, `description`, `event_type`
- `starts_at`, `ends_at`, `neighborhood`, `image_url`
- `featured`, `status`, `created_by`, `submitted_at`

**Actions:** Publish, feature, cancel, duplicate event.

### 10.5 Users management (`admin_users_screen.dart`)

**List view**

- Search: name, email, id.
- Filters: role (`customer`, `venueOwner`, `admin`), min points, created date.
- Columns: avatar, name, email, role, points, tier (computed), created_at, actions.

**User detail drawer / page**

- Profile fields from `users` + `user_rankings.total_points`.
- Role change (dropdown) — **admin only**, audit logged.
- Suspend/ban: set `metadata.suspended = true` or separate `user_status` column.
- View user's check-ins, bookings (as talent), owned venues.
- Impersonation: **do not implement** in v1 (security risk).

### 10.6 Pending submissions (`admin_pending_submissions_screen.dart`)

**Two tabs (from Flutter):**

#### Tab A — Pending venues

Queue for user-submitted or owner-submitted venues awaiting approval.

| Field | Description |
|-------|-------------|
| Venue name, type, neighborhood, address | From submission payload |
| Submitted by | `users.name` via `submitted_by` |
| Submitted at | Timestamp |
| Actions | **Approve** (creates/updates `venues`, publishes), **Reject** (with reason), **Request changes** |

On approve: set `published = true`, notify owner, optionally charge `venue_submission_fee` from settings.

#### Tab B — Pending events

Same pattern for events linked to venues.

**Overlap with verification:** Business license uploads are **not** the same as venue listing submissions—add a third queue **Verification** under `/submissions/verification` (see §10.7).

### 10.7 Business verification review (new — required)

Not a separate Flutter screen today; required for production.

**Queue:** `venues.verification_status = 'pending'`.

**Admin actions**

1. Load document via Edge Function `get-verification-document` (signed URL, service role).
2. **Approve** → `verification_status = 'approved'`, `verified = true`.
3. **Reject** → `verification_status = 'rejected'`, store `rejection_reason` in metadata.
4. Audit log entry.

### 10.8 VIP packages (`admin_vip_packages_screen.dart`, `admin_edit_vip_package_screen.dart`)

**Status today:** Mock. **Requires `vip_packages` table** (see §11).

**List:** Search, filter by venue, active/inactive.

**Package fields (from mock):**

- `venue_id`, optional `event_id`
- `package_name`, `description`, `price`
- `benefits` (JSON array of strings)
- `image_url`, `promoter_id`, `is_active`

**Actions:** Create, edit, deactivate, duplicate.

**Customer visibility:** Show on venue detail and discover promoted slots when `is_active` and within sale window.

### 10.9 Earnings & payouts (`admin_earnings_screen.dart`, `admin_withdraw_screen.dart`)

**Status today:** Mock transactions. **Requires `platform_transactions`, `withdrawals` tables** and Stripe Edge Functions.

**Earnings dashboard**

- Period selector: day / week / month / year.
- Tabs: Overview | Transactions (from Flutter `TabController`).
- Metrics: total revenue, venue submission fees, event submission fees, pending payments.
- Charts: revenue over time (line), breakdown by type (pie).

**Transactions list**

- Types: `venue_submission`, `event_submission`, `vip_purchase`, `subscription` (extensible).
- Columns: id, type, amount, description, user, date, status (`completed`, `pending`, `failed`).

**Withdraw flow (`admin_withdraw_screen.dart`)**

- Select Stripe connected account.
- Enter amount; validate against available balance.
- Call Edge Function `stripe-create-payout` (see `STRIPE_SETUP.md`).
- Record in `withdrawals` table; show confirmation and receipt link.

### 10.10 Stripe settings (`admin_stripe_keys_screen.dart`, `admin_stripe_accounts_screen.dart`)

**Stripe API keys screen**

- **Production requirement:** Store **secret key only** in Supabase Vault or Edge Function secrets—never in browser localStorage or client bundle.
- Publishable key may be exposed to client checkout flows.
- “Test & Save” calls Edge Function that validates keys against Stripe API.

**Stripe accounts screen**

- List rows from `stripe_accounts` (per `STRIPE_SETUP.md` SQL).
- Show: account name, email, last4, status, connected_at.
- Actions: set default, disconnect (soft delete), view in Stripe Dashboard (external link).

### 10.11 Admin settings (`admin_settings_screen.dart`)

**Platform configuration (persist to `platform_settings` table or JSON config):**

| Setting | Default (Flutter mock) | Description |
|---------|------------------------|-------------|
| `venue_submission_fee` | $50 | Fee to submit new venue for review |
| `event_submission_fee` | $25 | Fee to submit new event |
| `auto_approve_venues` | false | Skip manual review |
| `auto_approve_events` | false | Skip manual review |
| `require_payment` | true | Block submission until paid |

**Additional recommended settings**

- Maintenance mode banner message
- Featured venue/event slot limits
- Max upload size for verification docs
- Supported cities list (for discover filters)

### 10.12 Admin capabilities matrix

Use this matrix to verify RBAC. “Admin API” = server route or Edge Function with service role.

| Capability | Customer | venueOwner | admin | Admin API |
|------------|----------|------------|-------|-----------|
| View published venues | ✓ | ✓ | ✓ | — |
| Create check-in | ✓ | — | — | — |
| Manage own profile | ✓ | ✓ | ✓ | — |
| Browse customers (talent) | — | ✓ | ✓ | — |
| CRUD own venue promotions | — | ✓ | — | — |
| CRUD own talent bookings | — | ✓ | — | — |
| Upload verification doc | — | ✓ | — | — |
| List all users | — | — | ✓ | ✓ |
| Change user roles | — | — | ✓ | ✓ |
| Approve submissions | — | — | ✓ | ✓ |
| Review verification docs | — | — | ✓ | ✓ |
| CRUD any venue/event | — | — | ✓ | ✓ |
| Manage VIP packages | — | — | ✓ | ✓ |
| Configure Stripe keys | — | — | ✓ | ✓ |
| Initiate withdrawals | — | — | ✓ | ✓ |
| Edit platform settings | — | — | ✓ | ✓ |

### 10.13 Admin notifications (v2)

Placeholder in Flutter dashboard AppBar. Implement:

- New pending submission
- Verification document uploaded
- Failed payout
- User report / content flag (when moderation exists)

Deliver via email (Resend/SendGrid) + in-app notification bell.

---

## 11. Backend extensions required

The following are **not** in current migrations but are required for admin parity. Add as `004_web_platform.sql` (or numbered sequentially).

### 11.1 `events`

```sql
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id TEXT REFERENCES public.venues(id),
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  event_type TEXT NOT NULL DEFAULT 'Party',
  neighborhood TEXT,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  image_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending_review'
    CHECK (status IN ('draft', 'pending_review', 'published', 'cancelled')),
  featured BOOLEAN DEFAULT false,
  submitted_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- RLS: public read published; owners insert; admins full access (via service role or policy)
```

### 11.2 `vip_packages`

```sql
CREATE TABLE public.vip_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id TEXT NOT NULL REFERENCES public.venues(id),
  event_id UUID REFERENCES public.events(id),
  package_name TEXT NOT NULL,
  description TEXT DEFAULT '',
  price NUMERIC(10,2) NOT NULL,
  benefits JSONB DEFAULT '[]'::jsonb,
  image_url TEXT,
  promoter_id UUID REFERENCES public.users(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.3 `platform_settings` (singleton row)

```sql
CREATE TABLE public.platform_settings (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  venue_submission_fee NUMERIC(10,2) DEFAULT 50,
  event_submission_fee NUMERIC(10,2) DEFAULT 25,
  auto_approve_venues BOOLEAN DEFAULT false,
  auto_approve_events BOOLEAN DEFAULT false,
  require_payment BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.4 `platform_transactions`

```sql
CREATE TABLE public.platform_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id),
  type TEXT NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  stripe_payment_intent_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.5 `stripe_keys` (encrypted)

Store only publishable key in DB; secret in Vault. Admin reads/writes via Edge Function.

### 11.6 `withdrawals`

Per `STRIPE_SETUP.md` — link to `stripe_accounts` and Stripe transfer ids.

### 11.7 `admin_audit_log`

```sql
CREATE TABLE public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.users(id),
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id TEXT,
  payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 11.8 RLS policies to add

- Admin read/write on all tables: use `EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')` **or** restrict admin mutations to service role only (preferred).
- Storage: admin read on `business-verification` via Edge Function signed URLs only.
- `platform_settings`: read public fee amounts if needed for submission UI; write admin-only.

### 11.9 Edge Functions (minimum set)

| Function | Purpose |
|----------|---------|
| `admin-update-user-role` | Role changes + audit |
| `admin-approve-submission` | Venue/event approval |
| `admin-verification-signed-url` | View verification PDF/image |
| `stripe-validate-keys` | Test keys server-side |
| `stripe-create-payout` | Withdrawals |
| `stripe-webhook` | Payment status updates |

Deploy secrets: `STRIPE_SECRET_KEY`, `SUPABASE_SERVICE_ROLE_KEY` (never expose to browser).

---

## 12. Security and compliance

| Risk | Mitigation |
|------|------------|
| Stripe secret in Flutter client (`stripe_service.dart`) | **Remove from mobile**; web admin uses Edge Functions only |
| Anon key in `supabase_config.dart` | Acceptable for client; enforce RLS; rotate keys if leaked |
| Admin actions via anon client | Use service role on server routes only |
| Verification docs | Private bucket; admin access via short-lived signed URLs |
| Role escalation | Only admins can set `role = 'admin'`; validate in Edge Function |
| CSRF on Next.js | Use Supabase SSR cookie patterns |
| PII | Minimize exports; log access in `admin_audit_log` |

---

## 13. Repository layout (proposed)

```
thisishtx/
  apps/
    web-customer/          # Next.js — consumer app
    web-business/          # Next.js — venue owner app
    web-admin/             # Next.js — operations portal
  packages/
    shared-types/          # DB types, enums, ranking rules
    supabase-client/       # Typed wrappers
  supabase/
    migrations/            # Existing + 004_web_platform.sql
    functions/             # Edge Functions
  lib/                     # Existing Flutter app (unchanged reference)
  WEB_APP_BUILD_INSTRUCTIONS.md  # This file
```

**Cursor workflow tip:** Point the agent at this file + specific section (e.g. “Implement §10.6 Pending submissions”) + Flutter reference path.

---

## 14. Environment and deployment

### 14.1 Environment variables (web)

| Variable | Apps | Notes |
|----------|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | all | Same project as mobile |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | all | Public |
| `SUPABASE_SERVICE_ROLE_KEY` | admin API routes only | Server only |
| `STRIPE_SECRET_KEY` | Edge Functions | Never `NEXT_PUBLIC_` |
| `STRIPE_PUBLISHABLE_KEY` | checkout UI | Optional public |
| `NEXT_PUBLIC_MAPBOX_TOKEN` | customer | If using Mapbox |

### 14.2 Supabase Auth redirect URLs

Add for each deployed web origin:

- `https://app.wherethevibesat.com/auth/callback`
- `https://business.wherethevibesat.com/auth/callback`
- `https://admin.wherethevibesat.com/auth/callback`

Mobile OAuth (existing): `io.supabase.flutterquickstart://login-callback/`

### 14.3 Hosting

| App | Suggested host |
|-----|----------------|
| Customer + Business + Admin | Vercel (separate projects or monorepo workspaces) |
| Edge Functions | Supabase |
| Database | Supabase (project `wabtknktqnrxnffkgpzh`) |

### 14.4 CI

- Lint + typecheck on PR
- Run Supabase migration dry-run against staging branch
- E2E smoke: login as `admin@demo.com`, load dashboard KPIs

---

## 15. Implementation phases

### Phase 0 — Foundation (1–2 weeks)

- [ ] Monorepo scaffold (`apps/web-admin` first)
- [ ] Shared design tokens + Supabase SSR auth
- [ ] Apply existing migrations to staging
- [ ] Admin login + role middleware

### Phase 1 — Admin MVP (2–3 weeks)

- [ ] Migration `004_web_platform.sql`
- [ ] Dashboard KPIs (real queries)
- [ ] Venues CRUD + verification review
- [ ] Users list + role change + audit log
- [ ] Pending submissions (venues/events)
- [ ] Platform settings

### Phase 2 — Admin commerce (2 weeks)

- [ ] VIP packages CRUD
- [ ] Events CRUD
- [ ] Earnings + Stripe Edge Functions + withdrawals

### Phase 3 — Business web (2–3 weeks)

- [ ] Onboarding + verification upload
- [ ] Browse/book talent, promotions, bookings
- [ ] Settings + subscription display

### Phase 4 — Customer web (3–4 weeks)

- [ ] Discover, search, map, venue detail
- [ ] Check-in + ranking + favorites + profile
- [ ] Guest gate

### Phase 5 — Hardening (ongoing)

- [ ] Realtime, notifications, social (messages) — separate schema
- [ ] GPS check-in verification
- [ ] Mobile app switches from mocks to shared APIs

---

## 16. Flutter reference map

Use these paths when implementing a web feature—**read the Flutter screen first** for UX and field names.

### Customer (`lib/screens/wtva/`)

| Screen file | Web route (§8) |
|-------------|----------------|
| `app_shell.dart` | Layout / nav |
| `discover_screen.dart` | `/discover` |
| `discover_browse_sheet.dart`, `discover_quick_browse.dart` | Browse sheet + quick row on `/discover` — **[docs/DISCOVER_FILTER_UX_WEB.md](docs/DISCOVER_FILTER_UX_WEB.md)** |
| `events_browse_screen.dart`, `events_filters_sheet.dart` | `/discover/events` (search bar + Filters modal) |
| `neighborhood_venues_screen.dart` | `/discover/neighborhoods/:slug` |
| `search_screen.dart` | `/discover/search` |
| `map_search_screen.dart` | `/discover/map` |
| `venue_detail_screen.dart` | `/venues/:id` |
| `ranking_screen.dart` | `/ranking` |
| `check_in_sheet.dart`, `check_in/*` | `/check-in` |
| `wtva_profile_screen.dart` | `/profile` |
| `wtva_favorites_screen.dart` | `/profile/favorites` |
| `messages_screen.dart`, `chat/*` | `/messages` |
| `registration/registration_flow.dart` | `/auth/register` |
| `wtva_login_screen.dart` | `/auth/login` |

### Business (`lib/screens/business/`)

| Screen file | Web route (§9) |
|-------------|----------------|
| `business_shell.dart` | Layout |
| `business_home_screen.dart` | `/` |
| `browse/business_browse_flow.dart` | `/browse` |
| `bookings/business_bookings_flow.dart` | `/bookings` |
| `promotions/business_promotions_flow.dart` | `/promotions` |
| `business_registration_flow.dart` | `/onboarding` |

### Admin (`lib/screens/admin/`)

| Screen file | Admin route (§10) |
|-------------|-------------------|
| `admin_dashboard_screen.dart` | `/` |
| `admin_venues_screen.dart` | `/venues` |
| `admin_edit_venue_screen.dart` | `/venues/:id/edit` |
| `admin_events_screen.dart` | `/events` |
| `admin_users_screen.dart` | `/users` |
| `admin_pending_submissions_screen.dart` | `/submissions` |
| `admin_vip_packages_screen.dart` | `/vip-packages` |
| `admin_earnings_screen.dart` | `/earnings` |
| `admin_withdraw_screen.dart` | `/earnings/withdraw` |
| `admin_stripe_keys_screen.dart` | `/settings/stripe/keys` |
| `admin_settings_screen.dart` | `/settings` |

### Services & rules

| File | Purpose |
|------|---------|
| `lib/data/ranking_rules.dart` | Points + tiers |
| `lib/services/auth_service.dart` | Auth patterns |
| `lib/services/venue_repository.dart` | Venue queries |
| `lib/services/business_verification_service.dart` | Doc upload |
| `lib/models/user_role.dart` | Role enum |

---

## 17. Acceptance criteria checklist

Before calling the web platform “v1 complete”:

### Admin portal

- [ ] Only `admin` role can access admin host
- [ ] Dashboard metrics match database counts (not hardcoded)
- [ ] Full venue CRUD with featured + verification approve/reject
- [ ] Events and VIP packages backed by Postgres
- [ ] Pending submissions approve/reject updates published records
- [ ] Platform settings persist and affect submission flows
- [ ] Stripe secret never in client bundle; test payout works in Stripe test mode
- [ ] All admin mutations write to `admin_audit_log`

### Business web

- [ ] `venueOwner` registration creates auth user + venue row + pending verification
- [ ] Owner can CRUD promotions and talent bookings visible in mobile repos
- [ ] Browse shows customers with `user_rankings` sorted by points

### Customer web

- [ ] Discover and venue detail load from `venues`
- [ ] Check-in creates `check_ins` and increments points per `RankingRules`
- [ ] Ranking page reflects `user_rankings` and tier math
- [ ] Guest gate blocks check-in until login

### Cross-cutting

- [ ] Same Supabase project as Flutter app
- [ ] Design matches WTVA dark monochrome theme
- [ ] Documentation updated when schema changes (migrations + this file)

---

## Document maintenance

When the Flutter app or Supabase schema changes:

1. Update the relevant section in this file.
2. Add a migration under `supabase/migrations/`.
3. Note breaking changes in PR description.

**Last synced with repo:** Flutter `1.0.0+1`, migrations through `003_business_verification.sql`, admin screens in `lib/screens/admin/` (mock-backed modules flagged above).

---

*End of build instructions.*
