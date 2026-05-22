-- Where The Vibes At — core tables (run in Supabase SQL Editor)

-- Venues (text ids match app mock seeds: 1, 2, 3, 4)
CREATE TABLE IF NOT EXISTS venues (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  venue_type TEXT NOT NULL DEFAULT 'Restaurant',
  address TEXT,
  image_url TEXT,
  description TEXT,
  rating NUMERIC(3, 1) DEFAULT 4.5,
  distance_miles NUMERIC(5, 1) DEFAULT 0,
  full_stars INTEGER DEFAULT 5,
  half_star BOOLEAN DEFAULT false,
  logo_url TEXT,
  services JSONB DEFAULT '["Dine-in", "Takeaway"]'::jsonb,
  check_in_count INTEGER DEFAULT 0,
  is_open BOOLEAN DEFAULT true,
  hours_label TEXT DEFAULT 'Open until 2:00 AM',
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  owner_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "venues_select_all"
  ON venues FOR SELECT
  USING (true);

CREATE POLICY "venues_insert_owner"
  ON venues FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('venueOwner', 'admin')
    )
  );

CREATE POLICY "venues_update_owner"
  ON venues FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND (
      owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.role = 'admin'
      )
    )
  );

-- Check-ins
CREATE TABLE IF NOT EXISTS check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  venue_id TEXT NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  caption TEXT,
  image_url TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  points_awarded INTEGER DEFAULT 25,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "check_ins_select_all"
  ON check_ins FOR SELECT
  USING (true);

CREATE POLICY "check_ins_insert_own"
  ON check_ins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "check_ins_update_own"
  ON check_ins FOR UPDATE
  USING (auth.uid() = user_id);

-- Favorites
CREATE TABLE IF NOT EXISTS user_favorites (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  venue_id TEXT NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, venue_id)
);

ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "favorites_select_own"
  ON user_favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "favorites_insert_own"
  ON user_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "favorites_delete_own"
  ON user_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- Seed venues (idempotent)
INSERT INTO venues (id, name, venue_type, address, image_url, description, rating, distance_miles, full_stars, half_star, logo_url, services, check_in_count)
VALUES
  ('1', 'Barbarella Pizza', 'Restaurants', '123 Main St, Houston, TX',
   'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
   'Wood-fired pizza and late-night cocktails in Montrose.', 4.4, 4.9, 4, true,
   'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200&q=80',
   '["Dine-in", "Takeaway", "Delivery"]'::jsonb, 1289),
  ('2', 'Joe''s Strip Bar', 'Bars', '456 Richmond Ave, Houston, TX',
   'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
   'Live music, strong pours, and weekend crowds.', 4.8, 2.1, 5, false, null,
   '["Dine-in", "Live music"]'::jsonb, 892),
  ('3', 'The Dream Club', 'Night clubs', '789 Washington Ave, Houston, TX',
   'https://images.unsplash.com/photo-1571330735065-0aa5a2c2ce9c?w=800&q=80',
   'DJs, bottle service, and peak nightlife energy.', 3.0, 4.9, 3, false,
   'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=200&q=80',
   '["VIP", "Bottle service"]'::jsonb, 2104),
  ('4', 'Dream Land', 'Night clubs', '321 Main St, Houston, TX',
   'https://images.unsplash.com/photo-1566417713940-7c8aeb8c8a3a?w=800&q=80',
   'Underground club with rotating themed nights.', 4.2, 0.3, 4, true, null,
   '["Dine-in", "Takeaway", "Delivery"]'::jsonb, 567)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  venue_type = EXCLUDED.venue_type,
  image_url = EXCLUDED.image_url,
  rating = EXCLUDED.rating,
  distance_miles = EXCLUDED.distance_miles;
