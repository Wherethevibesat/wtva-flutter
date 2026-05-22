# Supabase Setup Guide

This guide will help you set up Supabase for **Where The Vibes At** (wherethevibesat).

## 1. Create a Supabase Project

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in your project details:
   - Name: `wherethevibesat`
   - Database Password: (choose a strong password)
   - Region: (choose closest to your users)
5. Click "Create new project" and wait for it to be created

## 2. Get Your API Keys

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (under "Project URL")
   - **anon public** key (under "Project API keys")

## 3. Configure the App

1. Open `lib/config/supabase_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
   With your actual values:
   ```dart
   static const String supabaseUrl = 'https://xxxxxxxxxxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

## 4. Create Database Tables (automated)

**Easiest — run one script** (from project root in PowerShell):

```powershell
cd c:\src\thisishtx
.\scripts\apply_supabase_migration.ps1
```

When prompted, paste your **database password** from:
[Supabase Dashboard → Settings → Database](https://supabase.com/dashboard/project/wabtknktqnrxnffkgpzh/settings/database)

Or pass it directly:

```powershell
.\scripts\apply_supabase_migration.ps1 -DbPassword 'YOUR_PASSWORD_HERE'
```

**No password / prefer the website?** Copies SQL to clipboard and opens the SQL Editor:

```powershell
.\scripts\apply_supabase_migration.ps1 -ClipboardOnly
```

Then paste (Ctrl+V) and click **Run**.

The script runs one file:

- `supabase/migrations/000_full_database.sql` — users, rankings, venues, check-ins, favorites, promotions, talent bookings, RLS, seed venues  
- `supabase/migrations/003_business_verification.sql` — business document storage bucket + venue verification fields  

Idempotent and safe to re-run.

**After updating:** run `003_business_verification.sql` in the Supabase SQL Editor so business license uploads work.

**Alternative (Node):**

```powershell
copy .env.example .env
# Edit .env and set SUPABASE_DB_PASSWORD=...
cd scripts
npm install
cd ..
node scripts/apply-db.mjs
```

### Manual option (SQL Editor)

### Users Table

```sql
-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  profile_image_url TEXT,
  role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('admin', 'venueOwner', 'customer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile (via trigger)
CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create function to automatically create user profile on signup
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
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
```

### Events Table (Optional - for future use)

```sql
-- Create events table
CREATE TABLE IF NOT EXISTS events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  venue_name TEXT NOT NULL,
  date TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  promoter_name TEXT,
  event_type TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Everyone can read events
CREATE POLICY "Events are viewable by everyone"
  ON events FOR SELECT
  USING (true);

-- Only venue owners and admins can create events
CREATE POLICY "Venue owners and admins can create events"
  ON events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('venueOwner', 'admin')
    )
  );
```

### Venues Table (Optional - for future use)

```sql
-- Create venues table
CREATE TABLE IF NOT EXISTS venues (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  venue_type TEXT NOT NULL,
  address TEXT,
  image_url TEXT,
  description TEXT,
  owner_id UUID REFERENCES users(id),
  operating_hours JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

-- Everyone can read venues
CREATE POLICY "Venues are viewable by everyone"
  ON venues FOR SELECT
  USING (true);

-- Only venue owners and admins can create venues
CREATE POLICY "Venue owners and admins can create venues"
  ON venues FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role IN ('venueOwner', 'admin')
    )
  );
```

## 5. Configure Authentication

1. Go to **Authentication** → **Settings** in your Supabase dashboard
2. Configure the following:
   - **Site URL**: Your app's URL (for web) or deep link (for mobile)
   - **Redirect URLs**: Add your app's redirect URLs
     - For mobile: `io.supabase.flutterquickstart://login-callback/`
     - For web: `http://localhost:3000/auth/callback`

3. Enable email authentication (should be enabled by default)

## 6. Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

## 7. Run modes

| Mode | Command | Behavior |
|------|---------|----------|
| **Production (default)** | `flutter run` | Real Supabase auth; venues, check-ins, points, favorites, and business data sync to the database. |
| **Offline demo** | `flutter run --dart-define=USE_DUMMY_AUTH=true` | Dummy login (`customer@demo.com` / `password`) without Supabase Auth. Venues may still load from Supabase if configured. |

Optional: disable remote venue fetch with `--dart-define=USE_SUPABASE_DATA=false`.

## 8. Test the Setup

1. Run the migration SQL, then `flutter run`
2. Demo login or sign up with `--dart-define=USE_DUMMY_AUTH=false`
3. Check **Authentication** → **Users** and **Table Editor** → **users**, **venues**, **check_ins**

## 9. Environment Variables (Optional - Recommended for Production)

For production, consider using environment variables instead of hardcoding:

1. Create a `.env` file in the root of your project:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_anon_key
   ```

2. Add `.env` to `.gitignore`

3. Use a package like `flutter_dotenv` to load these values

## Troubleshooting

### Issue: "Invalid API key"
- Make sure you copied the **anon public** key, not the service role key
- Check that there are no extra spaces in your config file

### Issue: "User profile not created"
- Check that the trigger function was created correctly
- Check Supabase logs for errors

### Issue: "Permission denied"
- Make sure Row Level Security policies are set up correctly
- Check that the user is authenticated

## Next Steps

- Set up OAuth providers (Google, Apple, etc.) if needed
- Configure email templates in Authentication → Email Templates
- Set up storage buckets for images if needed
- Configure real-time subscriptions if needed

