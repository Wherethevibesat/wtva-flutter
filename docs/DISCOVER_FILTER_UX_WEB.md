# Discover filter UX — Web implementation guide

**Purpose:** Replicate the mobile Discover header UX on **customer web** (and any other app that shows the main venue feed). Hand this document to Cursor agents or web developers building `app.wherethevibesat.com`.

**Mobile source of truth (implemented):**

| Flutter file | Role |
|--------------|------|
| `lib/screens/wtva/discover_screen.dart` | Discover page layout |
| `lib/widgets/wtva/discover_quick_browse.dart` | Events / Areas / Map shortcut row |
| `lib/screens/wtva/discover_browse_sheet.dart` | Secondary browse (event types + neighborhoods) |
| `lib/widgets/wtva/wtva_search_bar.dart` | Search field + filter affordance |
| `lib/widgets/wtva/wtva_category_chips.dart` | Primary venue category filters |
| `lib/data/mock_discover_data.dart` | Category labels for venue feed |
| `lib/data/event_types.dart` | Canonical event type list |
| `lib/services/neighborhoods_repository.dart` | Neighborhoods API |

**Related:** [WEB_APP_BUILD_INSTRUCTIONS.md](../WEB_APP_BUILD_INSTRUCTIONS.md) §8 (Customer web), §11 (events + neighborhoods schema).

---

## 1. Problem (do not replicate on web)

The **old** Discover layout exposed three horizontal chip rows under search:

1. “Browse by event type” (navigates away — does not filter the feed)
2. “Browse neighborhoods” (navigates away)
3. Venue categories: Nearest, Bars, Night clubs, Restaurants, Location (filters the feed)

Users could not tell which chips changed the list vs opened another screen. The header consumed too much vertical space before promoted venues and “Near you” content.

**Do not ship three always-visible chip carousels on `/discover`.**

---

## 2. UX principles

| Principle | Application |
|-----------|-------------|
| **One primary filter row** | Only controls that change the **current page’s venue list** stay visible (category chips). |
| **Progressive disclosure** | Event types and neighborhoods live in a **Browse** panel/sheet, not in the sticky header. |
| **Separate navigation from filtering** | Events and neighborhoods are **entry points** to other routes; venue categories are **in-place filters**. |
| **Consistent affordances** | Search bar **filter/tune** icon opens the same Browse UI as the **Areas** shortcut (with optional scroll-to section). |
| **Parity with mobile** | Same mental model across Flutter and web; responsive layout may differ (sheet vs dialog). |

---

## 3. Target layout on `/discover`

Top-to-bottom order in the Discover header region:

```
┌─────────────────────────────────────────────────────────┐
│ Discover                                    🔔  avatar  │
│ 📍 Houston, TX ▾                                        │
├─────────────────────────────────────────────────────────┤
│ [🔍 Search venues, events, people...        ] [⚙ tune] │  ← opens Browse
├─────────────────────────────────────────────────────────┤
│ [ Events ]    [ Areas ]    [ Map ]                      │  ← quick browse row
├─────────────────────────────────────────────────────────┤
│ (Nearest) (Bars) (Night clubs) (Restaurants) (Location) │  ← single chip row
├─────────────────────────────────────────────────────────┤
│ Promoted …                                              │
│ Near you …                                              │
│ (venue cards)                                           │
└─────────────────────────────────────────────────────────┘
```

### 3.1 Search bar

- **Tap/click field** → navigate to `/discover/search` (or focus inline search if you implement typeahead on the same page).
- **Filter (tune) button** → open **Discover Browse** UI (§4). Do **not** send filter-only users straight to the map unless product explicitly changes that.

Reference: `lib/widgets/wtva/wtva_search_bar.dart`

### 3.2 Quick browse row

Three equal-width tiles in one row:

| Tile | Label | Icon (Material) | Action |
|------|-------|-----------------|--------|
| 1 | **Events** | `event_outlined` | Navigate to `/discover/events` (no type pre-selected) |
| 2 | **Areas** | `place_outlined` | Open Discover Browse with `initialSection=areas` (§4) |
| 3 | **Map** | `map_outlined` | Navigate to `/discover/map` |

Styling (match design system):

- Background: `dark300` (`#2A2A2E` or token equivalent)
- Border: `night200` at ~85% opacity
- Radius: `12px`
- Padding: ~`10px` vertical; icon `20px`; label `12px` semibold `neutral100`

Reference: `lib/widgets/wtva/discover_quick_browse.dart`

### 3.3 Venue category chips (only visible filter row)

Horizontal scrollable chips; **one selected at a time**; selection updates the venue list on the same page.

| Index | Label | Behavior |
|-------|-------|----------|
| 0 | Nearest | Default; show all venues sorted by distance (or API default) |
| 1 | Bars | Filter venues where type/category = bar |
| 2 | Night clubs | Filter clubs |
| 3 | Restaurants | Filter restaurants |
| 4 | Location | Navigate to `/discover/map`; reset chip selection to Nearest when user returns |

**Data (v1 mock parity):** labels from `MockDiscoverData.categories` in `lib/data/mock_discover_data.dart`. **Production:** map to `venues.type` or a dedicated `venue_category` column — align with Supabase schema.

Selected chip: gradient primary button style (`buttonGradient` + shadow). Unselected: `dark400` fill, `night200` border.

Reference: `lib/widgets/wtva/wtva_category_chips.dart`

### 3.4 Below the header (unchanged)

- Promoted card
- “Near you” venue list (filtered by category chip)
- Live stories strip

---

## 4. Discover Browse UI (secondary)

Replaces the removed event-type and neighborhood chip rows on Discover.

### 4.1 Content

Two sections inside one scrollable container:

**Section A — Event type**

- Title: `Event type`
- Chips (wrap layout, not horizontal carousel):
  - `All events` → `/discover/events`
  - One chip per value in `WtvaEventTypes.all` (`lib/data/event_types.dart`):

```
Day Party
Night Party
After Hours
Brunch / Daytime
Live Music / DJ
Private Event
Other
```

Selecting a type → close panel → navigate to `/discover/events?type={encodeURIComponent(type)}`

**Section B — Neighborhood**

- Title: `Neighborhood`
- Load from Supabase `neighborhoods` table (`city`, `is_active = true`), same as `NeighborhoodsRepository.list()` in Flutter.
- Chips in a **wrap** (all neighborhoods visible by scrolling the panel — no second horizontal carousel on Discover).
- Selecting a neighborhood → close panel → navigate to `/discover/neighborhoods/[slug]` or `/discover/areas/[slug]` (pick one route pattern and stick to it).

**Empty state:** “No neighborhoods loaded yet.” if API returns `[]`.

### 4.2 `initialSection` behavior

When opened from **Areas** quick tile or filter button with `?section=areas`:

- Scroll/focus the Neighborhood section into view after open (mobile uses `Scrollable.ensureVisible`; web: `element.scrollIntoView({ behavior: 'smooth' })` or ref + `scrollIntoView`).

Allowed values: `events` | `areas` | omit for top of sheet.

Reference: `lib/screens/wtva/discover_browse_sheet.dart`

### 4.3 Responsive container

| Viewport | Container |
|----------|-----------|
| Mobile web (`< md`) | Bottom **sheet** / drawer from bottom, max height ~72vh, drag handle, close button |
| Desktop (`≥ md`) | **Modal dialog** centered, max-width ~480px, same content — or right **side panel** if design system prefers |

Use the same React component; swap wrapper (`Sheet` vs `Dialog`) via breakpoint.

**Do not** render Browse sections inline on `/discover` — always behind sheet/dialog.

---

## 5. Routes and query params

Add to customer web IA (extend [WEB_APP_BUILD_INSTRUCTIONS.md](../WEB_APP_BUILD_INSTRUCTIONS.md) §8.1):

| Route | Purpose | Flutter reference |
|-------|---------|-------------------|
| `/discover` | Main feed with layout in §3 | `discover_screen.dart` |
| `/discover/search` | Full search | `search_screen.dart` |
| `/discover/map` | Map + venue pins | `map_search_screen.dart` |
| `/discover/events` | Published events list | `events_browse_screen.dart` |
| `/discover/events?type=Night+Party` | Events filtered by type | `EventsBrowseScreen(initialEventType: …)` |
| `/discover/neighborhoods/:slug` | Venues/events in one neighborhood | `neighborhood_venues_screen.dart` |

**City picker:** keep existing pattern (`city_picker_sheet.dart`) — e.g. modal on city label click; Houston default for v1 demo data.

---

## 6. Events browse page (`/discover/events`)

Discover is decluttered; **filtering for events stays on the events page** (acceptable).

That page may still show:

- Event type chips (filters list in place)
- Neighborhood chips (filters list in place)

That is correct: users who navigated to Events expect filters there. **Do not** duplicate those rows back onto `/discover`.

Reference: `lib/screens/wtva/events_browse_screen.dart`

---

## 7. Data and API

| Data | Source | Notes |
|------|--------|-------|
| Venue feed | `venues` (+ distance sort if lat/lng known) | Category chip filters client- or server-side |
| Neighborhoods | `neighborhoods` | `name`, `slug`, `description`; filter `city` + `is_active` |
| Event types | **Static enum** | Share with admin: `lib/data/event_types.ts` on web must match `lib/data/event_types.dart` |
| Events list | `events` where `status = 'published'` | Filter by `event_type`, `neighborhood` query params |
| Promoted / stories | v1 mock or future tables | Unchanged |

---

## 8. Suggested web component tree (Next.js example)

```
app/discover/page.tsx
  DiscoverHeader
    CityPickerTrigger
    SearchBar onSearchNavigate onFilterOpen
    DiscoverQuickBrowse
    VenueCategoryChips
  DiscoverFeed (promoted, venues, stories)

components/discover/
  SearchBar.tsx
  DiscoverQuickBrowse.tsx
  VenueCategoryChips.tsx
  DiscoverBrowsePanel.tsx    // sheet + dialog wrappers
  useDiscoverBrowse.ts       // open/close, initialSection

app/discover/events/page.tsx
app/discover/neighborhoods/[slug]/page.tsx
app/discover/map/page.tsx
app/discover/search/page.tsx
```

Shared types:

```ts
// src/lib/types/event.ts — keep in sync with Flutter WtvaEventTypes.all
export const EVENT_TYPES = [
  'Day Party',
  'Night Party',
  // ...
] as const;

export type DiscoverBrowseSection = 'events' | 'areas';
```

---

## 9. Acceptance criteria

Use this checklist for PR review:

- [ ] `/discover` shows **at most one** horizontal chip row (venue categories only).
- [ ] No “Browse by event type” or “Browse neighborhoods” headings on `/discover`.
- [ ] Quick browse row with Events, Areas, Map is visible below search.
- [ ] Search filter icon opens Browse panel with Event type + Neighborhood sections.
- [ ] Areas tile opens Browse panel scrolled to Neighborhood section.
- [ ] Events tile goes to `/discover/events`.
- [ ] Map tile and Location category chip go to `/discover/map`.
- [ ] Selecting a venue category updates the venue list without a full page navigation.
- [ ] Browse panel uses wrap chips (not three stacked horizontal carousels).
- [ ] Event type / neighborhood picks navigate to the correct routes with query/slug params.
- [ ] Desktop and mobile both work; Browse uses sheet on small screens, dialog (or panel) on large.
- [ ] Guest users can browse; gated actions still use AccountGate pattern (unchanged).

---

## 10. Out of scope (unless requested)

- Applying the same declutter pattern to **business** `/browse` (talent filters use a different product pattern; see `business_browse_flow.dart`).
- Active filter summary pills (“Night clubs · Midtown”) on Discover.
- Changing **Events browse** internal filters (that screen keeps in-page chips).

---

## 11. Prompt snippet for Cursor / contractors

Copy-paste when starting web work:

```
Implement Discover filter UX per docs/DISCOVER_FILTER_UX_WEB.md.

Read Flutter references first:
- lib/screens/wtva/discover_screen.dart
- lib/widgets/wtva/discover_quick_browse.dart
- lib/screens/wtva/discover_browse_sheet.dart

On /discover: search bar + quick browse (Events/Areas/Map) + ONE venue category chip row.
Move event types and neighborhoods into a Browse sheet/dialog opened by filter icon or Areas tile.
Add routes /discover/events, /discover/neighborhoods/[slug], wire neighborhoods API and EVENT_TYPES enum.
Do not restore three chip carousels on the discover header.
Match WEB_APP_BUILD_INSTRUCTIONS design tokens (dark500 background, category chip gradient when selected).
```

---

## 12. Changelog

| Date | Change |
|------|--------|
| 2026-05-23 | Initial doc — mobile Discover declutter shipped; web parity spec |
