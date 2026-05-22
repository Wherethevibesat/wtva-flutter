# Where The Vibes At — Product Brief

**Where The Vibes At** (wherethevibesat) is a mobile-first social nightlife app: discover where to go, check in at venues, post photos, climb ranks, and connect with friends and promoters.

Originally scoped for Houston; the current build is **national** in positioning (venue discovery, ranks, and social feed—not a city-coded brand).

## What users do

| Job | In the app |
|-----|------------|
| Find where to go | Discover feed, map search, categories, promoted spots |
| Check in | FAB → pick venue → check in, create post, or go live |
| Build status | Points, tiers (Vibee → Influencers), global & follower leaderboards |
| Stay social | Messages, photos/videos hub, notifications, share check-ins |
| Manage presence | Profile, favorites, check-in history, settings |

## Core screens (WTVA)

- **Onboarding:** Splash, welcome slides, registration wizard, login, forgot password, terms
- **Discover:** Search, category chips, promoted card, venue cards, live stories
- **Ranking:** My rank, global ranks, followers, “how to get points”
- **Check-in:** Choose place, options sheet, create post, active check-in, go live (mock stream)
- **Venue detail:** Hero, tabs, recent check-ins, directions/call/check-in
- **Profile & More:** Edit profile, favorites, history, settings; map, messages, photos, promoter tools, help

## Roles

- **Customer** — browse, check in, rank up, social features
- **Venue owner / promoter** — promoter tools, promotions (mock)
- **Admin** — dashboard for venues, events, users, submissions, Stripe, VIP packages (separate admin UI)

## Tech stack

- **Flutter** (Material 3, dark theme)
- **Auth:** Supabase (optional) or dev dummy auth
- **Data today:** Mock stores under `lib/data/`; ready to swap for Supabase/API
- **Admin:** Legacy admin screens retained for operations; consumer UX is all under `lib/screens/wtva/`

## Design goals

- Match Figma hi-fi (Tendi / WTVA tokens: purple gradients, Urbanist, 375×812 patterns)
- Single cohesive dark nightlife aesthetic
- Clear check-in → points → rank loop

## Roadmap (not yet built)

- Real map SDK and location verification
- Live camera / streaming for Go Live and photo posts
- Full chat threads and real-time notifications
- Supabase-backed venues, check-ins, and leaderboards
- Deep links (e.g. Stripe Connect) wired in `main`

## Development approach

1. UI and flows with mock data (current)
2. Connect Supabase schema and auth (`useDummyAuth = false`)
3. Replace mocks with API/realtime
4. Harden admin and promoter paths against production data
