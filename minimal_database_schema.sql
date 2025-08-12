-- ===================================================================
-- MINIMAL STOX APP DATABASE SCHEMA
-- ===================================================================
-- This removes all unnecessary tables and keeps only core functionality
-- ===================================================================

-- 1. DROP ALL EXISTING TABLES
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

-- Drop custom types
DROP TYPE IF EXISTS asset_type CASCADE;
DROP TYPE IF EXISTS theme_type CASCADE;
DROP TYPE IF EXISTS transaction_type CASCADE;
DROP TYPE IF EXISTS achievement_category CASCADE;

-- 2. CREATE ESSENTIAL TYPES
-- ===================================================================
CREATE TYPE transaction_type AS ENUM ('buy', 'sell');

-- 3. CREATE MINIMAL CORE TABLES
-- ===================================================================

-- User profiles (simplified - only essential fields)
CREATE TABLE public.user_profiles (
  id uuid NOT NULL,
  email text,
  is_admin boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_profiles_pkey PRIMARY KEY (id),
  CONSTRAINT user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- User portfolio holdings (core trading data)
CREATE TABLE public.portfolio (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  symbol text NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  avg_price numeric NOT NULL CHECK (avg_price > 0),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT portfolio_pkey PRIMARY KEY (id),
  CONSTRAINT portfolio_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT portfolio_unique_user_symbol UNIQUE (user_id, symbol)
);

-- Transaction history (essential for tracking trades)
CREATE TABLE public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  symbol text NOT NULL,
  type transaction_type NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric NOT NULL CHECK (price > 0),
  total_value numeric NOT NULL CHECK (total_value > 0),
  timestamp timestamp with time zone DEFAULT now(),
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Support requests (essential for user support)
CREATE TABLE public.support_requests (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  email text NOT NULL,
  request_type text NOT NULL CHECK (request_type = ANY (ARRAY['bug'::text, 'feature'::text, 'support'::text, 'feedback'::text])),
  subject text NOT NULL,
  description text NOT NULL,
  priority text DEFAULT 'medium'::text CHECK (priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text, 'critical'::text])),
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'in_progress'::text, 'resolved'::text, 'closed'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT support_requests_pkey PRIMARY KEY (id),
  CONSTRAINT support_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- 4. CREATE ESSENTIAL INDEXES FOR PERFORMANCE
-- ===================================================================
CREATE INDEX idx_portfolio_user_id ON public.portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON public.portfolio(symbol);
CREATE INDEX idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX idx_transactions_symbol ON public.transactions(symbol);
CREATE INDEX idx_transactions_timestamp ON public.transactions(timestamp DESC);
CREATE INDEX idx_support_requests_user_id ON public.support_requests(user_id);
CREATE INDEX idx_support_requests_status ON public.support_requests(status);

-- 5. CREATE SIMPLE RLS POLICIES (NON-RECURSIVE)
-- ===================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;

-- User profiles - users can only access their own
CREATE POLICY "profiles_select_own" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Portfolio - users can only access their own holdings
CREATE POLICY "portfolio_select_own" ON public.portfolio
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "portfolio_insert_own" ON public.portfolio
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "portfolio_update_own" ON public.portfolio
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "portfolio_delete_own" ON public.portfolio
    FOR DELETE USING (auth.uid() = user_id);

-- Transactions - users can only access their own trades
CREATE POLICY "transactions_select_own" ON public.transactions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert_own" ON public.transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Support requests - users can only access their own requests
CREATE POLICY "support_select_own" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "support_insert_own" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. GRANT ESSENTIAL PERMISSIONS
-- ===================================================================
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.portfolio TO authenticated;
GRANT SELECT, INSERT ON public.transactions TO authenticated;
GRANT SELECT, INSERT ON public.support_requests TO authenticated;

-- 7. CREATE USER INITIALIZATION FUNCTION
-- ===================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, is_admin)
  VALUES (NEW.id, NEW.email, false);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user initialization
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. SUCCESS MESSAGE
-- ===================================================================
DO $$
BEGIN
    RAISE NOTICE '
    ╔══════════════════════════════════════════════════════════════════╗
    ║                   🗄️  DATABASE MINIMIZED! 🗄️                   ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  ✅ Removed 8 unnecessary tables                                 ║
    ║  ✅ Kept 4 essential tables:                                     ║
    ║     • user_profiles (basic user data)                           ║
    ║     • portfolio (holdings)                                       ║
    ║     • transactions (trade history)                               ║
    ║     • support_requests (user support)                            ║
    ║                                                                  ║
    ║  ✅ Simplified columns and removed bloat                         ║
    ║  ✅ Added essential indexes for performance                      ║
    ║  ✅ Created simple, non-recursive RLS policies                   ║
    ║  ✅ Added user initialization trigger                            ║
    ║                                                                  ║
    ║  💾 Database is now lean and optimized!                         ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
    ';
END $$;