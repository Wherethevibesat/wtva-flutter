-- Where The Vibes At — FULL database schema (idempotent, run once)
-- Combines 000_complete_setup + 002_business_and_rankings

-- ========== USERS (auth profiles) ==========
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  profile_image_url TEXT,
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('admin', 'venueOwner', 'customer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "venue_owners_read_customers" ON public.users;
CREATE POLICY "venue_owners_read_customers"
  ON public.users FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR (
      role = 'customer'
      AND EXISTS (
        SELECT 1 FROM public.users owner
        WHERE owner.id = auth.uid()
        AND owner.role IN ('venueOwner', 'admin')
      )
    )
  );

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ========== USER RANKINGS ==========
CREATE TABLE IF NOT EXISTS public.user_rankings (
  user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  total_points INTEGER NOT NULL DEFAULT 0 CHECK (total_points >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.user_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "rankings_select_authenticated" ON public.user_rankings;
CREATE POLICY "rankings_select_authenticated"
  ON public.user_rankings FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "rankings_upsert_own" ON public.user_rankings;
CREATE POLICY "rankings_upsert_own"
  ON public.user_rankings FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "rankings_update_own" ON public.user_rankings;
CREATE POLICY "rankings_update_own"
  ON public.user_rankings FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_new_user_ranking()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_rankings (user_id, total_points)
  VALUES (NEW.id, 0)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_user_created_ranking ON public.users;
CREATE TRIGGER on_user_created_ranking
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_ranking();

INSERT INTO public.user_rankings (user_id, total_points)
SELECT id, 0 FROM public.users
ON CONFLICT (user_id) DO NOTHING;

-- ========== VENUES ==========
CREATE TABLE IF NOT EXISTS public.venues (
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
  phone TEXT,
  categories JSONB DEFAULT '[]'::jsonb,
  subscription_tier TEXT DEFAULT 'gold' CHECK (subscription_tier IN ('silver', 'gold', 'platinum')),
  verified BOOLEAN DEFAULT false,
  payout_method TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "venues_select_all" ON public.venues;
CREATE POLICY "venues_select_all"
  ON public.venues FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "venues_insert_owner" ON public.venues;
CREATE POLICY "venues_insert_owner"
  ON public.venues FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role IN ('venueOwner', 'admin')
    )
  );

DROP POLICY IF EXISTS "venues_update_owner" ON public.venues;
CREATE POLICY "venues_update_owner"
  ON public.venues FOR UPDATE
  USING (
    auth.uid() IS NOT NULL
    AND (
      owner_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.users
        WHERE users.id = auth.uid() AND users.role = 'admin'
      )
    )
  );

DROP TRIGGER IF EXISTS update_venues_updated_at ON public.venues;
CREATE TRIGGER update_venues_updated_at
  BEFORE UPDATE ON public.venues
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ========== CHECK-INS ==========
CREATE TABLE IF NOT EXISTS public.check_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  caption TEXT,
  image_url TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  points_awarded INTEGER DEFAULT 25,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "check_ins_select_all" ON public.check_ins;
CREATE POLICY "check_ins_select_all"
  ON public.check_ins FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "check_ins_select_venue_owner" ON public.check_ins;
CREATE POLICY "check_ins_select_venue_owner"
  ON public.check_ins FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "check_ins_insert_own" ON public.check_ins;
CREATE POLICY "check_ins_insert_own"
  ON public.check_ins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "check_ins_update_own" ON public.check_ins;
CREATE POLICY "check_ins_update_own"
  ON public.check_ins FOR UPDATE
  USING (auth.uid() = user_id);

-- ========== FAVORITES ==========
CREATE TABLE IF NOT EXISTS public.user_favorites (
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, venue_id)
);

ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "favorites_select_own" ON public.user_favorites;
CREATE POLICY "favorites_select_own"
  ON public.user_favorites FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_insert_own" ON public.user_favorites;
CREATE POLICY "favorites_insert_own"
  ON public.user_favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_delete_own" ON public.user_favorites;
CREATE POLICY "favorites_delete_own"
  ON public.user_favorites FOR DELETE
  USING (auth.uid() = user_id);

-- ========== VENUE PROMOTIONS ==========
CREATE TABLE IF NOT EXISTS public.venue_promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'scheduled', 'live', 'ended')),
  detail TEXT DEFAULT '',
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.venue_promotions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "promotions_select_all" ON public.venue_promotions;
CREATE POLICY "promotions_select_all"
  ON public.venue_promotions FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "promotions_insert_owner" ON public.venue_promotions;
CREATE POLICY "promotions_insert_owner"
  ON public.venue_promotions FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = owner_id
    AND EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "promotions_update_owner" ON public.venue_promotions;
CREATE POLICY "promotions_update_owner"
  ON public.venue_promotions FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "promotions_delete_owner" ON public.venue_promotions;
CREATE POLICY "promotions_delete_owner"
  ON public.venue_promotions FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

DROP TRIGGER IF EXISTS update_venue_promotions_updated_at ON public.venue_promotions;
CREATE TRIGGER update_venue_promotions_updated_at
  BEFORE UPDATE ON public.venue_promotions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ========== TALENT BOOKINGS ==========
CREATE TABLE IF NOT EXISTS public.talent_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  talent_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'checkedIn', 'completed', 'cancelled')),
  event_at TIMESTAMPTZ NOT NULL,
  amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  note TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.talent_bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookings_select_involved" ON public.talent_bookings;
CREATE POLICY "bookings_select_involved"
  ON public.talent_bookings FOR SELECT
  TO authenticated
  USING (
    auth.uid() = owner_id
    OR auth.uid() = talent_user_id
    OR EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "bookings_insert_owner" ON public.talent_bookings;
CREATE POLICY "bookings_insert_owner"
  ON public.talent_bookings FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = owner_id
    AND EXISTS (
      SELECT 1 FROM public.venues v
      WHERE v.id = venue_id AND v.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "bookings_update_involved" ON public.talent_bookings;
CREATE POLICY "bookings_update_involved"
  ON public.talent_bookings FOR UPDATE
  TO authenticated
  USING (
    auth.uid() = owner_id
    OR auth.uid() = talent_user_id
  );

DROP TRIGGER IF EXISTS update_talent_bookings_updated_at ON public.talent_bookings;
CREATE TRIGGER update_talent_bookings_updated_at
  BEFORE UPDATE ON public.talent_bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ========== SEED VENUES ==========
INSERT INTO public.venues (id, name, venue_type, address, image_url, description, rating, distance_miles, full_stars, half_star, logo_url, services, check_in_count, is_open, hours_label, latitude, longitude)
VALUES
  ('1', 'Barbarella Pizza', 'Restaurants', '123 Main St, Houston, TX',
   'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
   'Wood-fired pizza and late-night cocktails in Montrose.', 4.4, 4.9, 4, true,
   'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=200&q=80',
   '["Dine-in", "Takeaway", "Delivery"]'::jsonb, 1289, true, 'Open until 2:00 AM',
   29.7424, -95.4018),
  ('2', 'Joe''s Strip Bar', 'Bars', '456 Richmond Ave, Houston, TX',
   'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
   'Live music, strong pours, and weekend crowds.', 4.8, 2.1, 5, false, null,
   '["Dine-in", "Live music"]'::jsonb, 892, true, 'Open until 2:00 AM',
   29.7604, -95.3698),
  ('3', 'The Dream Club', 'Night clubs', '789 Washington Ave, Houston, TX',
   'https://images.unsplash.com/photo-1571330735065-0aa5a2c2ce9c?w=800&q=80',
   'DJs, bottle service, and peak nightlife energy.', 3.0, 4.9, 3, false,
   'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=200&q=80',
   '["VIP", "Bottle service"]'::jsonb, 2104, true, 'Open until 2:00 AM',
   29.7632, -95.3612),
  ('4', 'Dream Land', 'Night clubs', '321 Main St, Houston, TX',
   'https://images.unsplash.com/photo-1566417713940-7c8aeb8c8a3a?w=800&q=80',
   'Underground club with rotating themed nights.', 4.2, 0.3, 4, true, null,
   '["Dine-in", "Takeaway", "Delivery"]'::jsonb, 567, true, 'Open until 2:00 AM',
   29.7581, -95.3546),
  ('post-oak', 'Post Oak Bar', 'Bars', '123 Main St, Houston, TX',
   'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
   'Premium nightlife destination in Houston.', 4.8, 1.2, 5, false, null,
   '["Bars", "Night clubs"]'::jsonb, 420, true, 'Open until 2:00 AM',
   29.7550, -95.3620)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  venue_type = EXCLUDED.venue_type,
  image_url = EXCLUDED.image_url,
  rating = EXCLUDED.rating,
  distance_miles = EXCLUDED.distance_miles,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  categories = COALESCE(public.venues.categories, EXCLUDED.categories),
  subscription_tier = COALESCE(public.venues.subscription_tier, EXCLUDED.subscription_tier);
