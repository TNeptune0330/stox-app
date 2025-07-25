# Manual Database Schema Check

## 🔍 Quick Check in Supabase Dashboard

Go to your Supabase dashboard and check these items:

### 1. Table Editor Check
Visit: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor

**Required Tables** (check if they exist):
- [ ] `users`
- [ ] `portfolio`
- [ ] `transactions`
- [ ] `market_prices`
- [ ] `achievement_progress`
- [ ] `user_achievements`
- [ ] `user_settings`
- [ ] `leaderboard`

### 2. SQL Editor Check
Visit: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor/20701

**Run these test queries:**

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

```sql
-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';
```

```sql
-- Check market_prices data
SELECT COUNT(*) as total_stocks FROM market_prices;
```

```sql
-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;
```

### 3. Authentication Check
Visit: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/auth

**Check:**
- [ ] Google OAuth provider is enabled (optional)
- [ ] Users table exists in Auth section

### 4. Expected Results

**If schema is set up correctly:**
- ✅ All 8 tables should exist
- ✅ Functions like `execute_trade` should exist
- ✅ Market_prices should have 70+ stock records
- ✅ RLS should be enabled on user tables

**If schema is missing:**
- ❌ Few or no tables exist
- ❌ No custom functions
- ❌ Empty market_prices table

## 🚀 If Schema is Missing

If you don't see the expected tables and functions:

1. **Copy the schema SQL** from `supabase_complete_schema.sql`
2. **Go to SQL Editor**: https://supabase.com/dashboard/project/dskcftkbfdkynjbxnwak/editor/20701
3. **Paste and run** the entire schema
4. **Verify** the tables and functions are created

## 🎯 What Each Table Does

- **users**: User profiles, cash balances, trading stats
- **portfolio**: Current stock holdings per user
- **transactions**: Trading history and P&L records
- **market_prices**: Current stock/crypto prices and market data
- **achievement_progress**: Progress tracking for achievements
- **user_achievements**: Unlocked achievements per user
- **user_settings**: User preferences and themes
- **leaderboard**: Global rankings and competition data

Let me know what you find when you check these items!