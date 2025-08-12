# Supabase Setup Instructions

## Current Issue
The app is trying to connect to `dskaftakbfdkynjbxnwak.supabase.co` but this URL is not resolving (DNS lookup fails).

## To Fix Supabase Connection:

### 1. Verify Your Supabase Project
1. Go to https://supabase.com/dashboard
2. Check if your project `stox-app` exists
3. Verify the project URL is correct

### 2. Get the Correct URL
1. In your Supabase dashboard, go to your project
2. Go to Settings → API
3. Copy the **Project URL** (should look like: `https://xxxxx.supabase.co`)
4. Copy the **anon public key**

### 3. Update the App Configuration
Update `lib/config/supabase_config.dart` with the correct values:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_ACTUAL_PROJECT_URL';
  static const String anonKey = 'YOUR_ACTUAL_ANON_KEY';
  static const bool useLocalStorage = false;
}
```

### 4. Set Up Database Schema
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and paste the content from `supabase_complete_schema.sql`
4. Run the SQL to create all tables and functions

### 5. Configure Google OAuth (Optional)
1. In Supabase dashboard → Authentication → Providers
2. Enable Google provider
3. Add your Google OAuth credentials

## Current Status
- ✅ **App works offline** - All features work with local storage
- ✅ **Price simulation** - Realistic price changes every 2 minutes
- ✅ **P&L calculations** - Real-time profit/loss display
- ✅ **Trading system** - Buy/sell stocks with proper validation
- ✅ **Achievement system** - Fixed type casting errors
- ✅ **UI overflow** - Fixed layout issues

## What Works Now (Offline Mode)
- User authentication (local storage)
- Portfolio management
- Stock trading with realistic prices
- Achievement tracking
- Market data simulation
- P&L calculations

## What Needs Supabase
- Cross-device data sync
- Cloud backup of portfolio
- Real-time leaderboards
- Achievement synchronization

The app is fully functional in offline mode! You can test all trading features while working on the Supabase setup.