-- Where The Vibes At — rankings, business bookings, promotions (idempotent)

-- ========== USER RANKINGS (lifetime points) ==========
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

-- Seed ranking row when profile is created
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

-- Backfill rankings for existing users
INSERT INTO public.user_rankings (user_id, total_points)
SELECT id, 0 FROM public.users
ON CONFLICT (user_id) DO NOTHING;

-- ========== USERS: allow venue owners to browse customers ==========
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

-- ========== VENUES: business profile fields ==========
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS categories JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'gold'
  CHECK (subscription_tier IN ('silver', 'gold', 'platinum'));
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT false;
ALTER TABLE public.venues ADD COLUMN IF NOT EXISTS payout_method TEXT;

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
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========== TALENT BOOKINGS (venue invites customers) ==========
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
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ========== CHECK-INS: owners read their venue check-ins ==========
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

-- Drop overly broad select if we want tighter security (keep public read for discover)
-- Existing check_ins_select_all remains for anonymous discover; owner policy adds nothing for anon.

-- ========== DEMO VENUE FOR BUSINESS (Post Oak) ==========
INSERT INTO public.venues (
  id, name, venue_type, address, image_url, description,
  rating, distance_miles, owner_id, categories, subscription_tier, verified, phone
)
VALUES (
  'post-oak',
  'Post Oak Bar',
  'Bars',
  '123 Main St, Houston, TX',
  'https://images.unsplash.com/photo-1571266028245-e68f8574baca?w=800&q=80',
  'Premium nightlife destination in Houston.',
  4.8, 1.2, NULL,
  '["Bars", "Night clubs"]'::jsonb,
  'gold', true, ''
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  categories = EXCLUDED.categories,
  subscription_tier = EXCLUDED.subscription_tier;
