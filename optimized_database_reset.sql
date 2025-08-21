-- STOX APP OPTIMIZED DATABASE SCHEMA
-- This script will reset your database to a clean, optimized state
-- Run this in your Supabase SQL Editor to reset everything

-- ============================================================
-- STEP 1: DROP ALL EXISTING TABLES AND CLEAN UP
-- ============================================================

-- Drop all existing tables and dependencies
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS market_prices CASCADE;
DROP TABLE IF EXISTS newsletters CASCADE;
DROP TABLE IF EXISTS price_alerts CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS portfolio CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop custom types if they exist
DROP TYPE IF EXISTS trade_type CASCADE;
DROP TYPE IF EXISTS asset_type CASCADE;
DROP TYPE IF EXISTS theme_type CASCADE;

-- Drop all existing functions
DROP FUNCTION IF EXISTS execute_trade CASCADE;
DROP FUNCTION IF EXISTS update_leaderboard CASCADE;
DROP FUNCTION IF EXISTS handle_new_user CASCADE;
DROP FUNCTION IF EXISTS update_user_last_login CASCADE;

-- Drop all triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;

-- ============================================================
-- STEP 2: CREATE CLEAN SCHEMA FOR STOX APP
-- ============================================================

-- Create essential enums
CREATE TYPE trade_type AS ENUM ('buy', 'sell');
CREATE TYPE theme_type AS ENUM ('light', 'dark', 'neon_navy', 'ocean_blue', 'forest_green', 'sunset_orange', 'lavender_purple', 'cherry_red', 'golden_yellow', 'mint_green', 'rose_gold', 'midnight_blue');

-- ============================================================
-- USERS TABLE - Core user data and settings
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
  
  -- Preferences
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
-- PORTFOLIO TABLE - User holdings
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
  category TEXT NOT NULL,
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
-- INDEXES FOR PERFORMANCE
-- ============================================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_updated_at ON users(updated_at);
CREATE INDEX idx_portfolio_user_id ON portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON portfolio(symbol);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_symbol ON transactions(symbol);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp DESC);
CREATE INDEX idx_achievements_user_id ON achievements(user_id);
CREATE INDEX idx_achievements_unlocked ON achievements(is_unlocked);
CREATE INDEX idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX idx_watchlist_symbol ON watchlist(symbol);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;

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

-- ============================================================
-- ESSENTIAL FUNCTIONS
-- ============================================================

-- Function to execute trades atomically
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
  new_avg_price NUMERIC;
  total_cost NUMERIC;
BEGIN
  -- Get current cash balance
  SELECT cash_balance INTO current_balance
  FROM users
  WHERE id = user_id_param;

  -- For buy orders
  IF type_param = 'buy' THEN
    -- Check if user has enough cash
    IF current_balance < total_amount_param THEN
      RETURN false; -- Insufficient funds
    END IF;

    -- Update cash balance
    UPDATE users
    SET cash_balance = cash_balance - total_amount_param,
        total_trades = total_trades + 1,
        updated_at = NOW()
    WHERE id = user_id_param;

    -- Insert or update portfolio
    INSERT INTO portfolio (user_id, symbol, quantity, avg_price)
    VALUES (user_id_param, symbol_param, quantity_param, price_param)
    ON CONFLICT (user_id, symbol) DO UPDATE SET
      quantity = portfolio.quantity + quantity_param,
      avg_price = ((portfolio.avg_price * portfolio.quantity) + (price_param * quantity_param)) / (portfolio.quantity + quantity_param),
      updated_at = NOW();

  -- For sell orders
  ELSE
    -- Get current quantity
    SELECT quantity INTO current_quantity
    FROM portfolio
    WHERE user_id = user_id_param AND symbol = symbol_param;

    -- Check if user has enough shares
    IF current_quantity IS NULL OR current_quantity < quantity_param THEN
      RETURN false; -- Insufficient shares
    END IF;

    -- Update cash balance
    UPDATE users
    SET cash_balance = cash_balance + total_amount_param,
        total_trades = total_trades + 1,
        updated_at = NOW()
    WHERE id = user_id_param;

    -- Update portfolio
    new_quantity := current_quantity - quantity_param;
    
    IF new_quantity = 0 THEN
      -- Remove from portfolio if selling all shares
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

  -- Insert transaction record
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
    COALESCE(NEW.raw_user_meta_data ->> 'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', NEW.email),
    NEW.created_at,
    COALESCE(NEW.last_sign_in_at, NEW.created_at),
    NOW()
  );
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

-- Trigger to update last login
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
-- SUMMARY
-- ============================================================
-- This schema includes only the essential tables for your app:
-- 1. users - Complete user profiles and settings
-- 2. portfolio - User stock holdings
-- 3. transactions - Trading history
-- 4. achievements - User accomplishments
-- 5. watchlist - User stock watchlist
--
-- REMOVED (as requested):
-- - market_prices (data comes from API)
-- - newsletters (data comes from API)
-- - price_alerts (not needed)
-- - leaderboard (not needed)
--
-- The schema is optimized for your Flutter app's data model
-- and includes proper RLS policies for security.