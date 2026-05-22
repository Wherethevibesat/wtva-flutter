-- Where The Vibes At — complete setup (idempotent, safe to re-run)
-- Run via: scripts/apply_supabase_migration.ps1

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

-- ========== SEED VENUES ==========
INSERT INTO public.venues (id, name, venue_type, address, image_url, description, rating, distance_miles, full_stars, half_star, logo_url, services, check_in_count)
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
