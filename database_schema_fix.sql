-- Database Schema Fix Script for Stox App
-- Run this in your Supabase SQL Editor to fix missing types and constraints

-- ===== STEP 1: Create Missing Custom Types =====
-- These types are referenced but not defined in your schema

-- Create asset_type enum (used in portfolio and transactions)
DO $$ BEGIN
    CREATE TYPE asset_type AS ENUM ('stock', 'etf', 'crypto');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create trade_type enum (used in transactions)
DO $$ BEGIN
    CREATE TYPE trade_type AS ENUM ('buy', 'sell');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create theme_type enum (used in users table)
DO $$ BEGIN
    CREATE TYPE theme_type AS ENUM ('light', 'dark', 'green', 'blue');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create achievement_category enum (used in user_achievements)
DO $$ BEGIN
    CREATE TYPE achievement_category AS ENUM ('trading', 'portfolio', 'social', 'milestone', 'streak', 'profit');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ===== STEP 2: Fix Column Types That Reference USER-DEFINED =====

-- Fix market_prices.type column
ALTER TABLE public.market_prices 
ALTER COLUMN type TYPE asset_type USING type::asset_type;

-- Fix portfolio.asset_type column  
ALTER TABLE public.portfolio 
ALTER COLUMN asset_type TYPE asset_type USING asset_type::asset_type;

-- Fix transactions.type column
ALTER TABLE public.transactions 
ALTER COLUMN type TYPE trade_type USING type::trade_type;

-- Fix transactions.asset_type column
ALTER TABLE public.transactions 
ALTER COLUMN asset_type TYPE asset_type USING asset_type::asset_type;

-- Fix user_achievements.achievement_category column
ALTER TABLE public.user_achievements 
ALTER COLUMN achievement_category TYPE achievement_category USING achievement_category::achievement_category;

-- Fix users.color_theme column
ALTER TABLE public.users 
ALTER COLUMN color_theme TYPE theme_type USING color_theme::theme_type;

-- ===== STEP 3: Add Missing Indexes for Performance =====

-- Portfolio indexes
CREATE INDEX IF NOT EXISTS idx_portfolio_user_id ON public.portfolio(user_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_symbol ON public.portfolio(symbol);
CREATE INDEX IF NOT EXISTS idx_portfolio_user_symbol ON public.portfolio(user_id, symbol);

-- Transaction indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_symbol ON public.transactions(symbol);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON public.transactions(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_timestamp ON public.transactions(user_id, timestamp DESC);

-- Market prices indexes
CREATE INDEX IF NOT EXISTS idx_market_prices_type ON public.market_prices(type);
CREATE INDEX IF NOT EXISTS idx_market_prices_symbol ON public.market_prices(symbol);
CREATE INDEX IF NOT EXISTS idx_market_prices_last_updated ON public.market_prices(last_updated DESC);

-- User achievements indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_category ON public.user_achievements(achievement_category);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON public.user_achievements(unlocked_at DESC);

-- Achievement progress indexes
CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_id ON public.achievement_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_achievement_id ON public.achievement_progress(achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_completed ON public.achievement_progress(is_completed);

-- User settings indexes
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_key ON public.user_settings(setting_key);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_key ON public.user_settings(user_id, setting_key);

-- Leaderboard indexes
CREATE INDEX IF NOT EXISTS idx_leaderboard_rank ON public.leaderboard(rank);
CREATE INDEX IF NOT EXISTS idx_leaderboard_net_worth ON public.leaderboard(net_worth DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_user_id ON public.leaderboard(user_id);

-- Support requests indexes
CREATE INDEX IF NOT EXISTS idx_support_requests_user_id ON public.support_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON public.support_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_requests_created_at ON public.support_requests(created_at DESC);

-- Telemetry indexes
CREATE INDEX IF NOT EXISTS idx_app_telemetry_user_id ON public.app_telemetry(user_id);
CREATE INDEX IF NOT EXISTS idx_app_telemetry_event_name ON public.app_telemetry(event_name);
CREATE INDEX IF NOT EXISTS idx_app_telemetry_created_at ON public.app_telemetry(created_at DESC);

-- ===== STEP 4: Enable Row Level Security (RLS) =====

-- Enable RLS on tables that need it
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

-- Market prices and admin notifications can be public read
ALTER TABLE public.market_prices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications DISABLE ROW LEVEL SECURITY;

-- ===== STEP 5: Create RLS Policies =====

-- Users table policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Portfolio table policies
DROP POLICY IF EXISTS "Users can read own portfolio" ON public.portfolio;
CREATE POLICY "Users can read own portfolio" ON public.portfolio
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own portfolio" ON public.portfolio;
CREATE POLICY "Users can manage own portfolio" ON public.portfolio
  FOR ALL USING (auth.uid() = user_id);

-- Transactions table policies
DROP POLICY IF EXISTS "Users can read own transactions" ON public.transactions;
CREATE POLICY "Users can read own transactions" ON public.transactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
CREATE POLICY "Users can insert own transactions" ON public.transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User achievements policies
DROP POLICY IF EXISTS "Users can read own achievements" ON public.user_achievements;
CREATE POLICY "Users can read own achievements" ON public.user_achievements
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own achievements" ON public.user_achievements;
CREATE POLICY "Users can manage own achievements" ON public.user_achievements
  FOR ALL USING (auth.uid() = user_id);

-- Achievement progress policies
DROP POLICY IF EXISTS "Users can read own achievement progress" ON public.achievement_progress;
CREATE POLICY "Users can read own achievement progress" ON public.achievement_progress
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own achievement progress" ON public.achievement_progress;
CREATE POLICY "Users can manage own achievement progress" ON public.achievement_progress
  FOR ALL USING (auth.uid() = user_id);

-- User settings policies
DROP POLICY IF EXISTS "Users can read own settings" ON public.user_settings;
CREATE POLICY "Users can read own settings" ON public.user_settings
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own settings" ON public.user_settings;
CREATE POLICY "Users can manage own settings" ON public.user_settings
  FOR ALL USING (auth.uid() = user_id);

-- Support requests policies
DROP POLICY IF EXISTS "Users can read own support requests" ON public.support_requests;
CREATE POLICY "Users can read own support requests" ON public.support_requests
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create support requests" ON public.support_requests;
CREATE POLICY "Users can create support requests" ON public.support_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Telemetry policies
DROP POLICY IF EXISTS "Users can insert own telemetry" ON public.app_telemetry;
CREATE POLICY "Users can insert own telemetry" ON public.app_telemetry
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Leaderboard policies (public read)
DROP POLICY IF EXISTS "Anyone can read leaderboard" ON public.leaderboard;
CREATE POLICY "Anyone can read leaderboard" ON public.leaderboard
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own leaderboard entry" ON public.leaderboard;
CREATE POLICY "Users can update own leaderboard entry" ON public.leaderboard
  FOR ALL USING (auth.uid() = user_id);

-- ===== STEP 6: Add Missing Constraints =====

-- Add unique constraint for portfolio (user_id, symbol) if not exists
DO $$ BEGIN
    ALTER TABLE public.portfolio ADD CONSTRAINT portfolio_user_symbol_unique UNIQUE (user_id, symbol);
EXCEPTION
    WHEN duplicate_table THEN null;
END $$;

-- Add unique constraint for user_settings (user_id, setting_key) if not exists
DO $$ BEGIN
    ALTER TABLE public.user_settings ADD CONSTRAINT user_settings_user_key_unique UNIQUE (user_id, setting_key);
EXCEPTION
    WHEN duplicate_table THEN null;
END $$;

-- Add unique constraint for achievement progress (user_id, achievement_id) if not exists
DO $$ BEGIN
    ALTER TABLE public.achievement_progress ADD CONSTRAINT achievement_progress_user_achievement_unique UNIQUE (user_id, achievement_id);
EXCEPTION
    WHEN duplicate_table THEN null;
END $$;

-- ===== STEP 7: Insert Sample Data (Optional) =====

-- Insert some sample market data if table is empty
INSERT INTO public.market_prices (symbol, name, price, change_24h, change_percent_24h, type, exchange) VALUES
('AAPL', 'Apple Inc.', 175.43, 2.15, 1.24, 'stock', 'NASDAQ'),
('GOOGL', 'Alphabet Inc.', 138.25, -1.85, -1.32, 'stock', 'NASDAQ'),
('MSFT', 'Microsoft Corporation', 378.85, 4.23, 1.13, 'stock', 'NASDAQ'),
('AMZN', 'Amazon.com Inc.', 151.94, -2.41, -1.56, 'stock', 'NASDAQ'),
('TSLA', 'Tesla Inc.', 248.50, 12.35, 5.23, 'stock', 'NASDAQ'),
('NVDA', 'NVIDIA Corporation', 875.28, 15.42, 1.79, 'stock', 'NASDAQ'),
('META', 'Meta Platforms Inc.', 504.20, -8.15, -1.59, 'stock', 'NASDAQ'),
('AVGO', 'Broadcom Inc.', 1298.45, 22.30, 1.75, 'stock', 'NASDAQ'),
('ABBV', 'AbbVie Inc.', 175.60, 1.25, 0.72, 'stock', 'NYSE'),
('AMD', 'Advanced Micro Devices', 179.63, 5.44, 3.13, 'stock', 'NASDAQ'),
('SPY', 'SPDR S&P 500 ETF Trust', 536.92, 2.84, 0.53, 'etf', 'NYSEARCA'),
('QQQ', 'Invesco QQQ Trust', 475.29, 4.12, 0.88, 'etf', 'NASDAQ'),
('SOXL', 'Direxion Daily Semiconductor Bull 3X', 26.88, 1.15, 4.47, 'etf', 'NASDAQ'),
('BTC-USD', 'Bitcoin', 67845.32, 1247.85, 1.87, 'crypto', 'CRYPTO'),
('ETH-USD', 'Ethereum', 3456.78, -89.23, -2.52, 'crypto', 'CRYPTO')
ON CONFLICT (symbol) DO NOTHING;

-- ===== COMPLETION MESSAGE =====
DO $$ BEGIN
    RAISE NOTICE '✅ Database schema fix completed successfully!';
    RAISE NOTICE '📊 Fixed missing enum types: asset_type, trade_type, theme_type, achievement_category';
    RAISE NOTICE '🔗 Updated column references from USER-DEFINED to proper types';
    RAISE NOTICE '🚀 Added performance indexes for all major tables';
    RAISE NOTICE '🔒 Enabled RLS and created security policies';
    RAISE NOTICE '📝 Added unique constraints for data integrity';
    RAISE NOTICE '💾 Inserted sample market data for testing';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Your database is now fully compatible with the Stox app!';
END $$;