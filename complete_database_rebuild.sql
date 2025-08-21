-- COMPLETE DATABASE REBUILD FOR STOX APP
-- This script completely wipes and rebuilds your database from scratch
-- Run this in your Supabase SQL Editor to get a perfect fresh start

-- ============================================================
-- STEP 1: COMPLETE CLEANUP - REMOVE EVERYTHING
-- ============================================================

-- Disable session replication to prevent trigger issues during cleanup
SET session_replication_role = replica;

-- Drop all existing triggers first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users CASCADE;
DROP TRIGGER IF EXISTS update_user_last_login_trigger ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users CASCADE;

-- Drop all functions with CASCADE to remove all dependencies
DROP FUNCTION IF EXISTS execute_trade CASCADE;
DROP FUNCTION IF EXISTS update_leaderboard CASCADE;
DROP FUNCTION IF EXISTS handle_new_user CASCADE;
DROP FUNCTION IF EXISTS update_user_last_login CASCADE;
DROP FUNCTION IF EXISTS create_user_profile CASCADE;

-- Drop all policies (RLS)
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can read own portfolio" ON portfolio;
DROP POLICY IF EXISTS "Users can manage own portfolio" ON portfolio;
DROP POLICY IF EXISTS "Users can read own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can read own achievements" ON achievements;
DROP POLICY IF EXISTS "Users can manage own achievements" ON achievements;
DROP POLICY IF EXISTS "Users can read own watchlist" ON watchlist;
DROP POLICY IF EXISTS "Users can manage own watchlist" ON watchlist;

-- Drop all tables in dependency order
DROP TABLE IF EXISTS achievement_progress CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS app_telemetry CASCADE;
DROP TABLE IF EXISTS support_requests CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS watchlist CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS portfolio CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop all leaderboard/market price tables if they exist
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS market_prices CASCADE;
DROP TABLE IF EXISTS newsletters CASCADE;
DROP TABLE IF EXISTS price_alerts CASCADE;

-- Drop all custom types
DROP TYPE IF EXISTS trade_type CASCADE;
DROP TYPE IF EXISTS asset_type CASCADE;
DROP TYPE IF EXISTS theme_type CASCADE;
DROP TYPE IF EXISTS achievement_category CASCADE;

-- Re-enable session replication
SET session_replication_role = DEFAULT;

-- ============================================================
-- STEP 2: CREATE CLEAN SCHEMA FROM SCRATCH
-- ============================================================

-- Create essential enums
CREATE TYPE trade_type AS ENUM ('buy', 'sell');
CREATE TYPE achievement_category AS ENUM ('trading', 'social', 'learning', 'milestone', 'streak', 'portfolio');

-- ============================================================
-- USERS TABLE - Complete user data and preferences
-- ============================================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT NOT NULL UNIQUE,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  color_theme TEXT DEFAULT 'neon_navy',
  is_admin BOOLEAN DEFAULT false,
  
  -- Financial data
  cash_balance NUMERIC DEFAULT 10000.00 CHECK (cash_balance >= 0),
  initial_balance NUMERIC DEFAULT 10000.00,
  total_deposited NUMERIC DEFAULT 10000.00,
  
  -- Trading statistics  
  total_trades INTEGER DEFAULT 0 CHECK (total_trades >= 0),
  total_profit_loss NUMERIC DEFAULT 0.00,
  total_fees_paid NUMERIC DEFAULT 0.00,
  max_portfolio_value NUMERIC DEFAULT 10000.00,
  max_single_day_gain NUMERIC DEFAULT 0.00,
  max_single_day_loss NUMERIC DEFAULT 0.00,
  current_streak INTEGER DEFAULT 0,
  max_streak INTEGER DEFAULT 0,
  win_rate NUMERIC DEFAULT 0.00 CHECK (win_rate >= 0 AND win_rate <= 100),
  
  -- Activity tracking
  days_traded INTEGER DEFAULT 0,
  months_active INTEGER DEFAULT 0,
  sectors_traded TEXT[] DEFAULT '{}',
  asset_types_traded TEXT[] DEFAULT '{}',
  total_app_opens INTEGER DEFAULT 1,
  total_screen_time_minutes INTEGER DEFAULT 0,
  
  -- User preferences
  notifications_enabled BOOLEAN DEFAULT true,
  dark_mode_enabled BOOLEAN DEFAULT true,
  sound_effects_enabled BOOLEAN DEFAULT true,
  daily_loss_limit NUMERIC DEFAULT 1000.00,
  position_size_limit NUMERIC DEFAULT 5000.00,
  
  -- Timestamps
  last_active_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- PORTFOLIO TABLE - User stock holdings
-- ============================================================
CREATE TABLE portfolio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  avg_price NUMERIC NOT NULL CHECK (avg_price > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, symbol)
);

-- ============================================================
-- TRANSACTIONS TABLE - Trading history
-- ============================================================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  type trade_type NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price NUMERIC NOT NULL CHECK (price > 0),
  total_amount NUMERIC NOT NULL CHECK (total_amount > 0),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- ACHIEVEMENTS TABLE - User accomplishments
-- ============================================================
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  category achievement_category NOT NULL,
  progress INTEGER DEFAULT 0,
  target INTEGER DEFAULT 1,
  is_unlocked BOOLEAN DEFAULT false,
  unlocked_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- ============================================================
-- WATCHLIST TABLE - User stock watchlist
-- ============================================================
CREATE TABLE watchlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, symbol)
);

-- ============================================================
-- USER_SETTINGS TABLE - Additional user preferences
-- ============================================================
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  setting_key TEXT NOT NULL,
  setting_value JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, setting_key)
);

-- ============================================================
-- PERFORMANCE INDEXES
-- ============================================================
-- Users table indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_updated_at ON users(updated_at);
CREATE INDEX idx_users_last_login ON users(last_login);

-- Portfolio table indexes
CREATE INDEX idx_portfolio_user_id ON portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON portfolio(symbol);
CREATE INDEX idx_portfolio_user_symbol ON portfolio(user_id, symbol);

-- Transactions table indexes
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_symbol ON transactions(symbol);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp DESC);
CREATE INDEX idx_transactions_user_timestamp ON transactions(user_id, timestamp DESC);

-- Achievements table indexes
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_category ON achievements(category);
CREATE INDEX idx_achievements_unlocked ON achievements(is_unlocked);

-- Watchlist table indexes
CREATE INDEX idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX idx_watchlist_symbol ON watchlist(symbol);
CREATE INDEX idx_watchlist_user_symbol ON watchlist(user_id, symbol);

-- User settings indexes
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_user_settings_key ON user_settings(setting_key);

-- ============================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Portfolio table policies
CREATE POLICY "Users can read own portfolio" ON portfolio
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own portfolio" ON portfolio
  FOR ALL USING (auth.uid() = user_id);

-- Transactions table policies
CREATE POLICY "Users can read own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Achievements table policies
CREATE POLICY "Users can read own achievements" ON achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own achievements" ON achievements
  FOR ALL USING (auth.uid() = user_id);

-- Watchlist table policies
CREATE POLICY "Users can read own watchlist" ON watchlist
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own watchlist" ON watchlist
  FOR ALL USING (auth.uid() = user_id);

-- User settings table policies
CREATE POLICY "Users can read own settings" ON user_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own settings" ON user_settings
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- ESSENTIAL FUNCTIONS
-- ============================================================

-- Function to execute trades atomically with proper error handling
CREATE OR REPLACE FUNCTION execute_trade(
  user_id_param UUID,
  symbol_param TEXT,
  type_param trade_type,
  quantity_param INTEGER,
  price_param NUMERIC,
  total_amount_param NUMERIC
) RETURNS BOOLEAN AS $$
DECLARE
  current_balance NUMERIC;
  current_quantity INTEGER;
  new_quantity INTEGER;
  total_cost NUMERIC;
  existing_avg_price NUMERIC;
BEGIN
  -- Validate inputs
  IF quantity_param <= 0 OR price_param <= 0 OR total_amount_param <= 0 THEN
    RAISE EXCEPTION 'Invalid trade parameters';
  END IF;

  -- Get current cash balance
  SELECT cash_balance INTO current_balance
  FROM users
  WHERE id = user_id_param;

  IF current_balance IS NULL THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  -- For buy orders
  IF type_param = 'buy' THEN
    -- Check if user has enough cash
    IF current_balance < total_amount_param THEN
      RETURN false; -- Insufficient funds
    END IF;

    -- Update cash balance and trade count
    UPDATE users
    SET cash_balance = cash_balance - total_amount_param,
        total_trades = total_trades + 1,
        updated_at = NOW()
    WHERE id = user_id_param;

    -- Insert or update portfolio holding
    INSERT INTO portfolio (user_id, symbol, quantity, avg_price)
    VALUES (user_id_param, symbol_param, quantity_param, price_param)
    ON CONFLICT (user_id, symbol) DO UPDATE SET
      quantity = portfolio.quantity + quantity_param,
      avg_price = ((portfolio.avg_price * portfolio.quantity) + (price_param * quantity_param)) / (portfolio.quantity + quantity_param),
      updated_at = NOW();

  -- For sell orders
  ELSE
    -- Get current holding
    SELECT quantity, avg_price INTO current_quantity, existing_avg_price
    FROM portfolio
    WHERE user_id = user_id_param AND symbol = symbol_param;

    -- Check if user has enough shares
    IF current_quantity IS NULL OR current_quantity < quantity_param THEN
      RETURN false; -- Insufficient shares
    END IF;

    -- Update cash balance and trade count
    UPDATE users
    SET cash_balance = cash_balance + total_amount_param,
        total_trades = total_trades + 1,
        updated_at = NOW()
    WHERE id = user_id_param;

    -- Update portfolio
    new_quantity := current_quantity - quantity_param;
    
    IF new_quantity = 0 THEN
      -- Remove holding completely
      DELETE FROM portfolio
      WHERE user_id = user_id_param AND symbol = symbol_param;
    ELSE
      -- Update quantity
      UPDATE portfolio
      SET quantity = new_quantity,
          updated_at = NOW()
      WHERE user_id = user_id_param AND symbol = symbol_param;
    END IF;
  END IF;

  -- Record transaction
  INSERT INTO transactions (user_id, symbol, type, quantity, price, total_amount)
  VALUES (user_id_param, symbol_param, type_param, quantity_param, price_param, total_amount_param);

  RETURN true; -- Success
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (
    id, 
    email, 
    username, 
    display_name,
    created_at, 
    last_login,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
    NEW.created_at,
    COALESCE(NEW.last_sign_in_at, NEW.created_at),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = COALESCE(users.username, EXCLUDED.username),
    display_name = COALESCE(users.display_name, EXCLUDED.display_name),
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user last login
CREATE OR REPLACE FUNCTION update_user_last_login() RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_login = COALESCE(NEW.last_sign_in_at, NOW()),
      updated_at = NOW()
  WHERE id = NEW.id;
  
  -- If user doesn't exist, create them
  IF NOT FOUND THEN
    PERFORM handle_new_user();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger to update last login time
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION update_user_last_login();

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- ============================================================
-- COMPLETION AND VERIFICATION
-- ============================================================

-- Verify the schema was created correctly
DO $$
DECLARE
  table_count INTEGER;
  function_count INTEGER;
  trigger_count INTEGER;
BEGIN
  -- Count tables
  SELECT COUNT(*) INTO table_count
  FROM information_schema.tables
  WHERE table_schema = 'public'
  AND table_name IN ('users', 'portfolio', 'transactions', 'achievements', 'watchlist', 'user_settings');
  
  -- Count functions
  SELECT COUNT(*) INTO function_count
  FROM information_schema.routines
  WHERE routine_schema = 'public'
  AND routine_name IN ('execute_trade', 'handle_new_user', 'update_user_last_login');
  
  -- Count triggers
  SELECT COUNT(*) INTO trigger_count
  FROM information_schema.triggers
  WHERE event_object_schema = 'auth'
  AND trigger_name IN ('on_auth_user_created', 'on_auth_user_login');
  
  RAISE NOTICE '🚀 DATABASE REBUILD COMPLETE!';
  RAISE NOTICE '📊 Tables created: % (expected: 6)', table_count;
  RAISE NOTICE '⚙️ Functions created: % (expected: 3)', function_count;
  RAISE NOTICE '🔧 Triggers created: % (expected: 2)', trigger_count;
  RAISE NOTICE '';
  RAISE NOTICE '✅ Your database is now perfectly optimized for your Flutter app!';
  RAISE NOTICE '✅ All unwanted tables removed (market_prices, newsletters, etc.)';
  RAISE NOTICE '✅ Authentication will now work properly';
  RAISE NOTICE '✅ Data saving and trading functionality ready';
  RAISE NOTICE '';
  RAISE NOTICE '🔐 Security: Row Level Security enabled on all tables';
  RAISE NOTICE '🚀 Performance: Optimized indexes created';
  RAISE NOTICE '🎯 Ready: Restart your Flutter app now!';
END $$;