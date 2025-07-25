# Supabase Setup Steps for stox-app

## ✅ Step 1: URL Fixed
The Supabase URL has been corrected from `dskaftakbfdkynjbxnwak` to `dskcftkbfdkynjbxnwak`.

## 📋 Step 2: Database Schema Setup

### Go to your Supabase SQL Editor:
1. Visit: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor/20701
2. Create a new query
3. Copy and paste the entire content from `supabase_complete_schema.sql`
4. Run the query to create all tables and functions

## 🔑 Step 3: Configure Google OAuth (Optional)

### In your Supabase dashboard:
1. Go to Authentication → Providers
2. Enable Google provider
3. Add your Google OAuth credentials:
   - **Client ID**: `264305191086-ruelf34qlbnngfubd7m52418hta9c3oh.apps.googleusercontent.com`
   - **Client Secret**: You'll need to get this from Google Cloud Console

## 🚀 Step 4: Test the Connection

After setting up the database schema, rebuild and run the app:

```bash
flutter clean
flutter build apk --debug
```

## 🎯 What You Should See

Once the database is set up, you should see:
- ✅ No more "Failed host lookup" errors
- ✅ Data syncing to Supabase
- ✅ User profiles created in the database
- ✅ Portfolio data stored in the cloud
- ✅ Achievements synced across devices

## 🔧 If You Still Have Issues

If you encounter any issues after running the schema:

1. **Check the SQL Editor for errors** - Look for any red error messages
2. **Verify RLS policies** - Make sure Row Level Security is enabled
3. **Check API keys** - Ensure the anon key matches your project
4. **Test with a simple query** - Try `SELECT * FROM users;` in SQL Editor

## 📊 Database Tables Created

The schema will create these tables:
- `users` - User profiles and cash balances
- `portfolio` - User stock holdings
- `transactions` - Trading history
- `market_prices` - Stock price data
- `achievement_progress` - Achievement tracking
- `user_achievements` - Unlocked achievements
- `user_settings` - User preferences
- `leaderboard` - Global rankings

## 🎮 Ready to Trade!

Once the database is set up, all your trading data will be stored in Supabase and sync across devices!