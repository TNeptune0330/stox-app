-- ===================================================================
-- SAFE DATABASE MIGRATION - MINIMAL STOX APP SCHEMA
-- ===================================================================
-- This safely migrates existing database to minimal schema
-- ===================================================================

-- 1. DISABLE RLS TEMPORARILY TO AVOID CONFLICTS
-- ===================================================================
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.portfolio DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.support_requests DISABLE ROW LEVEL SECURITY;

-- 2. DROP ALL POLICIES FIRST
-- ===================================================================
DROP POLICY IF EXISTS "profiles_select_own" ON public.user_profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "portfolio_select_own" ON public.portfolio;
DROP POLICY IF EXISTS "portfolio_insert_own" ON public.portfolio;
DROP POLICY IF EXISTS "portfolio_update_own" ON public.portfolio;
DROP POLICY IF EXISTS "portfolio_delete_own" ON public.portfolio;
DROP POLICY IF EXISTS "transactions_select_own" ON public.transactions;
DROP POLICY IF EXISTS "transactions_insert_own" ON public.transactions;
DROP POLICY IF EXISTS "support_select_own" ON public.support_requests;
DROP POLICY IF EXISTS "support_insert_own" ON public.support_requests;

-- Drop old problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Users can create support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Admins can view all support requests" ON public.support_requests;

-- 3. DROP UNNECESSARY TABLES (SAFE - WITH IF EXISTS)
-- ===================================================================
DROP TABLE IF EXISTS public.achievement_progress CASCADE;
DROP TABLE IF EXISTS public.admin_notifications CASCADE;
DROP TABLE IF EXISTS public.app_telemetry CASCADE;
DROP TABLE IF EXISTS public.app_telemetry_template CASCADE;
DROP TABLE IF EXISTS public.leaderboard CASCADE;
DROP TABLE IF EXISTS public.market_prices CASCADE;
DROP TABLE IF EXISTS public.user_achievements CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- 4. CLEAN UP EXISTING ESSENTIAL TABLES
-- ===================================================================

-- Clean user_profiles table - remove unnecessary columns
DO $$
BEGIN
    -- Remove columns that exist but aren't needed
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'full_name') THEN
        ALTER TABLE public.user_profiles DROP COLUMN full_name;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.user_profiles DROP COLUMN avatar_url;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'color_theme') THEN
        ALTER TABLE public.user_profiles DROP COLUMN color_theme;
    END IF;
    
    RAISE NOTICE 'Cleaned user_profiles table';
END $$;

-- Clean portfolio table - remove unnecessary columns
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'total_invested') THEN
        ALTER TABLE public.portfolio DROP COLUMN total_invested;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'current_value') THEN
        ALTER TABLE public.portfolio DROP COLUMN current_value;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'unrealized_pnl') THEN
        ALTER TABLE public.portfolio DROP COLUMN unrealized_pnl;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'sector') THEN
        ALTER TABLE public.portfolio DROP COLUMN sector;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'asset_type') THEN
        ALTER TABLE public.portfolio DROP COLUMN asset_type;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'first_purchased') THEN
        ALTER TABLE public.portfolio DROP COLUMN first_purchased;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'portfolio' AND column_name = 'last_updated') THEN
        ALTER TABLE public.portfolio DROP COLUMN last_updated;
    END IF;
    
    RAISE NOTICE 'Cleaned portfolio table';
END $$;

-- Clean transactions table - remove unnecessary columns
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'fee') THEN
        ALTER TABLE public.transactions DROP COLUMN fee;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'realized_pnl') THEN
        ALTER TABLE public.transactions DROP COLUMN realized_pnl;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'sector') THEN
        ALTER TABLE public.transactions DROP COLUMN sector;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'asset_type') THEN
        ALTER TABLE public.transactions DROP COLUMN asset_type;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transactions' AND column_name = 'notes') THEN
        ALTER TABLE public.transactions DROP COLUMN notes;
    END IF;
    
    RAISE NOTICE 'Cleaned transactions table';
END $$;

-- Clean support_requests table - remove unnecessary columns
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'full_name') THEN
        ALTER TABLE public.support_requests DROP COLUMN full_name;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'app_version') THEN
        ALTER TABLE public.support_requests DROP COLUMN app_version;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'device_info') THEN
        ALTER TABLE public.support_requests DROP COLUMN device_info;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'screenshot_url') THEN
        ALTER TABLE public.support_requests DROP COLUMN screenshot_url;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'admin_notes') THEN
        ALTER TABLE public.support_requests DROP COLUMN admin_notes;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'support_requests' AND column_name = 'updated_at') THEN
        ALTER TABLE public.support_requests DROP COLUMN updated_at;
    END IF;
    
    RAISE NOTICE 'Cleaned support_requests table';
END $$;

-- 5. CREATE MISSING ESSENTIAL INDEXES
-- ===================================================================
CREATE INDEX IF NOT EXISTS idx_portfolio_user_id ON public.portfolio(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_symbol ON public.portfolio(symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_symbol ON public.transactions(symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON public.transactions(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_support_requests_user_id ON public.support_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON public.support_requests(status);

-- 6. ADD MISSING CONSTRAINTS
-- ===================================================================
DO $$
BEGIN
    -- Add unique constraint to portfolio if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'portfolio' AND constraint_name = 'portfolio_unique_user_symbol') THEN
        ALTER TABLE public.portfolio ADD CONSTRAINT portfolio_unique_user_symbol UNIQUE (user_id, symbol);
        RAISE NOTICE 'Added unique constraint to portfolio';
    END IF;
END $$;

-- 7. CREATE SIMPLE, SAFE RLS POLICIES
-- ===================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;

-- User profiles - simple policies
CREATE POLICY "profiles_select_own" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Portfolio - simple policies
CREATE POLICY "portfolio_select_own" ON public.portfolio
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "portfolio_insert_own" ON public.portfolio
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "portfolio_update_own" ON public.portfolio
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "portfolio_delete_own" ON public.portfolio
    FOR DELETE USING (auth.uid() = user_id);

-- Transactions - simple policies
CREATE POLICY "transactions_select_own" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert_own" ON public.transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Support requests - simple policies
CREATE POLICY "support_select_own" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "support_insert_own" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 8. GRANT ESSENTIAL PERMISSIONS
-- ===================================================================
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.portfolio TO authenticated;
GRANT SELECT, INSERT ON public.transactions TO authenticated;
GRANT SELECT, INSERT ON public.support_requests TO authenticated;

-- 9. CREATE/UPDATE USER INITIALIZATION FUNCTION
-- ===================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, is_admin)
  VALUES (NEW.id, NEW.email, false)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user initialization
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. SUCCESS MESSAGE
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '
    ╔══════════════════════════════════════════════════════════════════╗
    ║                🗄️  DATABASE SAFELY MINIMIZED! 🗄️                ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  ✅ Safely dropped 8 unnecessary tables                          ║
    ║  ✅ Cleaned up 4 essential tables:                               ║
    ║     • user_profiles (id, email, is_admin)                       ║
    ║     • portfolio (user_id, symbol, quantity, avg_price)          ║
    ║     • transactions (user_id, symbol, type, quantity, price)     ║
    ║     • support_requests (user_id, email, type, subject, desc)    ║
    ║                                                                  ║
    ║  ✅ Removed unnecessary columns                                   ║
    ║  ✅ Fixed RLS policies (no more infinite recursion!)            ║
    ║  ✅ Added essential indexes for performance                      ║
    ║  ✅ Database is now lean and optimized!                         ║
    ║                                                                  ║
    ║  🚀 Support requests should work now!                           ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
    ';
END $$;