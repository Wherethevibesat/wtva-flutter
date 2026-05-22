# Stripe API Keys Setup Guide

This guide will help you set up Stripe API keys for **Where The Vibes At** (admin payouts). Deep-link handling is not wired in the current app build; use this doc when you re-enable Stripe Connect callbacks.

## 1. Create Stripe Account

1. Go to [https://dashboard.stripe.com/register](https://dashboard.stripe.com/register)
2. Sign up for a Stripe account (or log in if you already have one)
3. Complete the account setup process

## 2. Get Your Stripe API Keys

1. In your Stripe Dashboard, go to **Settings** → **API keys**
2. You'll see two keys:
   - **Publishable key** (starts with `pk_test_` for test mode or `pk_live_` for live mode)
   - **Secret key** (starts with `sk_test_` for test mode or `sk_live_` for live mode)
3. Click "Reveal test key" or "Reveal live key" to see your secret key
4. Copy both keys - you'll enter them in the app

## 3. Add API Keys in the App

1. Open the app and navigate to **Admin** → **Settings** → **Stripe API Keys**
2. Enter your Publishable key
3. Enter your Secret key
4. Click "Test & Save" to verify the keys work
5. The keys will be saved securely in your database

## 4. Create Database Table for Stripe Keys

Run this SQL in your Supabase SQL Editor:

### Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add intent filter to your main activity:
   ```xml
   <activity
       android:name=".MainActivity"
       ...>
       <!-- Existing intent filters -->
       
       <!-- Stripe Connect callback -->
       <intent-filter>
           <action android:name="android.intent.action.VIEW" />
           <category android:name="android.intent.category.DEFAULT" />
           <category android:name="android.intent.category.BROWSABLE" />
           <data
               android:scheme="wherethevibesat"
               android:host="stripe-connect-callback" />
       </intent-filter>
   </activity>
   ```

### iOS

1. Open `ios/Runner/Info.plist`
2. Add URL scheme:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>wherethevibesat</string>
           </array>
       </dict>
   </array>
   ```

## 7. Create Supabase Database Tables

Run this SQL in your Supabase SQL Editor:

```sql
-- Create stripe_accounts table
CREATE TABLE IF NOT EXISTS stripe_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stripe_account_id TEXT NOT NULL UNIQUE,
  account_name TEXT NOT NULL,
  email TEXT,
  last4 TEXT,
  account_type TEXT DEFAULT 'express',
  is_default BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active',
  connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE stripe_accounts ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users can only see their own accounts
CREATE POLICY "Users can view own stripe accounts"
  ON stripe_accounts FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own accounts
CREATE POLICY "Users can insert own stripe accounts"
  ON stripe_accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own accounts
CREATE POLICY "Users can update own stripe accounts"
  ON stripe_accounts FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own accounts
CREATE POLICY "Users can delete own stripe accounts"
  ON stripe_accounts FOR DELETE
  USING (auth.uid() = user_id);

-- Create index for faster queries
CREATE INDEX idx_stripe_accounts_user_id ON stripe_accounts(user_id);
CREATE INDEX idx_stripe_accounts_stripe_account_id ON stripe_accounts(stripe_account_id);
```

## 6. Test the Integration

1. Run your Flutter app
2. Navigate to Admin → Settings → Stripe API Keys
3. Enter your test API keys (pk_test_... and sk_test_...)
4. Click "Test & Save"
5. If successful, you'll see a confirmation message
6. You can now create withdrawals from the Earnings screen

## Security Notes

- **Never expose your secret key** in client-side code (the current implementation stores it in the database, but in production, consider using Supabase Vault or encryption)
- Use test keys during development
- Switch to live keys only when ready for production
- Regularly rotate your API keys
- Monitor your Stripe dashboard for suspicious activity

## Troubleshooting

### Issue: "Stripe connection failed"
- Verify your API keys are correct
- Check that you're using test keys in test mode and live keys in live mode
- Ensure your Stripe account is fully activated

### Issue: "Keys not saving"
- Check Supabase database table exists
- Verify Row Level Security policies are set correctly
- Ensure user is authenticated

### Issue: "Withdrawal failed"
- Verify your Stripe account has sufficient balance
- Check that the bank account ID is correct
- Review Stripe dashboard for error details

## Next Steps

- Set up webhook handlers for withdrawal status updates
- Add support for multiple bank accounts
- Implement withdrawal history tracking
- Add encryption for secret keys (use Supabase Vault)

---

## Old Stripe Connect Setup (Deprecated)

<details>
<summary>Click to view old OAuth-based setup (not recommended)</summary>

The following setup was for Stripe Connect OAuth, but we've simplified to direct API key entry:

You'll need to create two Supabase Edge Functions:

### Function 1: `stripe-connect-callback`

This function handles the OAuth callback and exchanges the authorization code for an access token.

Create `supabase/functions/stripe-connect-callback/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') || ''
const STRIPE_CLIENT_ID = Deno.env.get('STRIPE_CLIENT_ID') || ''

serve(async (req) => {
  try {
    const { code } = await req.json()
    
    // Exchange authorization code for access token
    const response = await fetch('https://connect.stripe.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        client_id: STRIPE_CLIENT_ID,
        code: code,
      }),
    })
    
    const data = await response.json()
    
    if (!response.ok) {
      throw new Error(data.error_description || 'Failed to connect account')
    }
    
    // Get account details from Stripe
    const accountResponse = await fetch(`https://api.stripe.com/v1/accounts/${data.stripe_user_id}`, {
      headers: {
        'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
      },
    })
    
    const accountData = await accountResponse.json()
    
    // Store in database
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    const { data: user } = await supabaseClient.auth.getUser(
      req.headers.get('Authorization')?.replace('Bearer ', '') || ''
    )
    
    await supabaseClient.from('stripe_accounts').insert({
      user_id: user.user?.id,
      stripe_account_id: data.stripe_user_id,
      account_name: accountData.business_profile?.name || accountData.email || 'Stripe Account',
      email: accountData.email,
      last4: accountData.external_accounts?.data[0]?.last4 || null,
      account_type: accountData.type || 'express',
      status: accountData.charges_enabled ? 'active' : 'pending',
      metadata: {
        access_token: data.access_token, // Store securely, consider encrypting
        refresh_token: data.refresh_token,
      },
    })
    
    return new Response(
      JSON.stringify({ 
        success: true,
        account_id: data.stripe_user_id,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
```

### Function 2: `stripe-create-payout`

This function creates a payout to a connected Stripe account.

Create `supabase/functions/stripe-create-payout/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@14.21.0?target=deno'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') || ''
const stripe = new Stripe(STRIPE_SECRET_KEY, { apiVersion: '2023-10-16' })

serve(async (req) => {
  try {
    const { account_id, amount } = await req.json()
    
    // Get account from database
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )
    
    const { data: account } = await supabaseClient
      .from('stripe_accounts')
      .select('*')
      .eq('stripe_account_id', account_id)
      .single()
    
    if (!account) {
      throw new Error('Account not found')
    }
    
    // Create transfer to connected account
    const transfer = await stripe.transfers.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: 'usd',
      destination: account.stripe_account_id,
    })
    
    // Record withdrawal in database (create withdrawals table)
    await supabaseClient.from('withdrawals').insert({
      user_id: account.user_id,
      stripe_account_id: account.stripe_account_id,
      amount: amount,
      status: 'pending',
      stripe_transfer_id: transfer.id,
    })
    
    return new Response(
      JSON.stringify({ 
        success: true,
        transfer_id: transfer.id,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})
```

## 9. Set Environment Variables in Supabase

1. Go to your Supabase Dashboard → **Project Settings** → **Edge Functions** → **Secrets**
2. Add the following secrets:
   - `STRIPE_SECRET_KEY`: Your Stripe secret key (starts with `sk_`)
   - `STRIPE_CLIENT_ID`: Your Stripe Connect client ID (starts with `ca_`)

## 10. Deploy Edge Functions

```bash
# Install Supabase CLI if not already installed
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref your-project-ref

# Deploy functions
supabase functions deploy stripe-connect-callback
supabase functions deploy stripe-create-payout
```

## 11. Test the Integration

1. Run your Flutter app
2. Navigate to Admin → Earnings → Withdraw → Manage Stripe Accounts
3. Click "Connect New Stripe Account"
4. Complete the Stripe OAuth flow
5. Verify the account appears in your connected accounts list

## Security Notes

- Never expose your Stripe secret key in the client app
- Always perform Stripe API calls on your backend
- Store access tokens securely (consider encryption)
- Use Row Level Security policies to protect user data
- Validate all amounts and account IDs on the backend

## Troubleshooting

### Issue: "Invalid client_id"
- Verify your Stripe Connect Client ID is correct
- Check that Connect is enabled in your Stripe Dashboard

### Issue: "Redirect URI mismatch"
- Ensure the redirect URI in Stripe Dashboard matches your app's deep link
- Check that deep linking is properly configured in your app

### Issue: "OAuth callback not working"
- Verify deep linking is set up correctly for your platform
- Check that the redirect URI matches exactly (case-sensitive)

### Issue: "Account not saving"
- Check Supabase Edge Function logs
- Verify database table exists and RLS policies are correct
- Ensure user is authenticated

## Next Steps

- Set up webhook handlers for payout status updates
- Add withdrawal history tracking
- Implement account verification status
- Add support for multiple currencies

