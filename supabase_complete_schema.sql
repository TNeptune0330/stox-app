-- Complete Stox App Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor to create all tables from scratch

-- Drop existing tables if they exist (in correct order to avoid foreign key conflicts)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS update_user_last_login();
DROP FUNCTION IF EXISTS execute_trade(UUID, TEXT, trade_type, INTEGER, NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS update_leaderboard();

DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS achievement_progress CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS leaderboard CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS portfolio CASCADE;
DROP TABLE IF EXISTS market_prices CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Drop custom types if they exist
DROP TYPE IF EXISTS trade_type CASCADE;
DROP TYPE IF EXISTS asset_type CASCADE;
DROP TYPE IF EXISTS theme_type CASCADE;
DROP TYPE IF EXISTS achievement_category CASCADE;

-- Create custom types
CREATE TYPE trade_type AS ENUM ('buy', 'sell');
CREATE TYPE asset_type AS ENUM ('stock', 'etf', 'crypto', 'forex');
CREATE TYPE theme_type AS ENUM ('light', 'dark', 'green', 'blue', 'purple', 'orange');
CREATE TYPE achievement_category AS ENUM ('trading', 'profit', 'streak', 'special', 'milestone');

-- Users table (extends auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT NOT NULL,
  username TEXT UNIQUE,
  display_name TEXT,
  avatar_url TEXT,
  color_theme theme_type DEFAULT 'dark',
  cash_balance NUMERIC DEFAULT 10000.00 CHECK (cash_balance >= 0),
  total_trades INTEGER DEFAULT 0 CHECK (total_trades >= 0),
  total_profit_loss NUMERIC DEFAULT 0.00,
  max_portfolio_value NUMERIC DEFAULT 10000.00,
  current_streak INTEGER DEFAULT 0,
  max_streak INTEGER DEFAULT 0,
  days_traded INTEGER DEFAULT 0,
  first_trade_date TIMESTAMP WITH TIME ZONE,
  last_trade_date TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User settings table for preferences
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  setting_key TEXT NOT NULL,
  setting_value JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, setting_key)
);

-- Portfolio holdings table
CREATE TABLE portfolio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  avg_price NUMERIC NOT NULL CHECK (avg_price > 0),
  total_invested NUMERIC NOT NULL CHECK (total_invested > 0),
  current_value NUMERIC DEFAULT 0,
  unrealized_pnl NUMERIC DEFAULT 0,
  sector TEXT,
  asset_type asset_type DEFAULT 'stock',
  first_purchased TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, symbol)
);

-- Transaction history table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  type trade_type NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price NUMERIC NOT NULL CHECK (price > 0),
  total_value NUMERIC NOT NULL CHECK (total_value > 0),
  fee NUMERIC DEFAULT 0 CHECK (fee >= 0),
  realized_pnl NUMERIC DEFAULT 0,
  sector TEXT,
  asset_type asset_type DEFAULT 'stock',
  notes TEXT,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Market prices cache table
CREATE TABLE market_prices (
  symbol TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC NOT NULL CHECK (price > 0),
  change_24h NUMERIC DEFAULT 0,
  change_percent_24h NUMERIC DEFAULT 0,
  volume_24h NUMERIC DEFAULT 0,
  market_cap NUMERIC DEFAULT 0,
  sector TEXT,
  type asset_type NOT NULL,
  exchange TEXT,
  currency TEXT DEFAULT 'USD',
  is_active BOOLEAN DEFAULT true,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievement progress tracking table
CREATE TABLE achievement_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  current_progress INTEGER DEFAULT 0,
  target_progress INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  progress_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- User achievements table (unlocked achievements)
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  achievement_title TEXT NOT NULL,
  achievement_description TEXT NOT NULL,
  achievement_category achievement_category NOT NULL,
  icon_name TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Leaderboard table
CREATE TABLE leaderboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  net_worth NUMERIC NOT NULL DEFAULT 0,
  total_pnl NUMERIC NOT NULL DEFAULT 0,
  total_pnl_percentage NUMERIC NOT NULL DEFAULT 0,
  total_trades INTEGER NOT NULL DEFAULT 0,
  win_rate NUMERIC DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  max_streak INTEGER DEFAULT 0,
  achievements_count INTEGER DEFAULT 0,
  rank INTEGER,
  previous_rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_updated_at ON users(updated_at);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_user_settings_key ON user_settings(setting_key);

CREATE INDEX idx_portfolio_user_id ON portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON portfolio(symbol);
CREATE INDEX idx_portfolio_sector ON portfolio(sector);
CREATE INDEX idx_portfolio_asset_type ON portfolio(asset_type);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_symbol ON transactions(symbol);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_transactions_sector ON transactions(sector);
CREATE INDEX idx_transactions_asset_type ON transactions(asset_type);

CREATE INDEX idx_market_prices_type ON market_prices(type);
CREATE INDEX idx_market_prices_sector ON market_prices(sector);
CREATE INDEX idx_market_prices_updated ON market_prices(last_updated);
CREATE INDEX idx_market_prices_active ON market_prices(is_active);

CREATE INDEX idx_achievement_progress_user_id ON achievement_progress(user_id);
CREATE INDEX idx_achievement_progress_achievement_id ON achievement_progress(achievement_id);
CREATE INDEX idx_achievement_progress_completed ON achievement_progress(is_completed);

CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_category ON user_achievements(achievement_category);
CREATE INDEX idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

CREATE INDEX idx_leaderboard_rank ON leaderboard(rank);
CREATE INDEX idx_leaderboard_net_worth ON leaderboard(net_worth);
CREATE INDEX idx_leaderboard_total_pnl ON leaderboard(total_pnl);
CREATE INDEX idx_leaderboard_updated_at ON leaderboard(updated_at);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for user_settings table
CREATE POLICY "Users can manage own settings" ON user_settings
  FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for portfolio table
CREATE POLICY "Users can read own portfolio" ON portfolio
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own portfolio" ON portfolio
  FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for transactions table
CREATE POLICY "Users can read own transactions" ON transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions" ON transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for achievement_progress table
CREATE POLICY "Users can manage own achievement progress" ON achievement_progress
  FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for user_achievements table
CREATE POLICY "Users can read own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policies for leaderboard (public read, own write)
CREATE POLICY "Anyone can read leaderboard" ON leaderboard
  FOR SELECT USING (true);

CREATE POLICY "Users can update own leaderboard entry" ON leaderboard
  FOR ALL USING (auth.uid() = user_id);

-- Market prices is public read (no RLS needed)
ALTER TABLE market_prices DISABLE ROW LEVEL SECURITY;

-- Function to execute trades atomically
CREATE OR REPLACE FUNCTION execute_trade(
  user_id_param UUID,
  symbol_param TEXT,
  type_param trade_type,
  quantity_param INTEGER,
  price_param NUMERIC,
  total_value_param NUMERIC,
  sector_param TEXT DEFAULT NULL,
  asset_type_param asset_type DEFAULT 'stock'
) RETURNS JSONB AS $$
DECLARE
  current_balance NUMERIC;
  current_quantity INTEGER;
  current_avg_price NUMERIC;
  new_quantity INTEGER;
  new_avg_price NUMERIC;
  new_total_invested NUMERIC;
  realized_pnl NUMERIC := 0;
  result JSONB;
BEGIN
  -- Get current cash balance
  SELECT cash_balance INTO current_balance
  FROM users
  WHERE id = user_id_param;

  -- For buy orders
  IF type_param = 'buy' THEN
    -- Check if user has enough cash
    IF current_balance < total_value_param THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Insufficient funds',
        'required', total_value_param,
        'available', current_balance
      );
    END IF;

    -- Update cash balance and user stats
    UPDATE users
    SET 
      cash_balance = cash_balance - total_value_param,
      total_trades = total_trades + 1,
      last_trade_date = NOW(),
      updated_at = NOW()
    WHERE id = user_id_param;

    -- Set first trade date if this is the first trade
    UPDATE users
    SET first_trade_date = NOW()
    WHERE id = user_id_param AND first_trade_date IS NULL;

    -- Insert or update portfolio
    INSERT INTO portfolio (user_id, symbol, quantity, avg_price, total_invested, sector, asset_type)
    VALUES (user_id_param, symbol_param, quantity_param, price_param, total_value_param, sector_param, asset_type_param)
    ON CONFLICT (user_id, symbol) DO UPDATE SET
      quantity = portfolio.quantity + quantity_param,
      avg_price = ((portfolio.avg_price * portfolio.quantity) + (price_param * quantity_param)) / (portfolio.quantity + quantity_param),
      total_invested = portfolio.total_invested + total_value_param,
      last_updated = NOW(),
      updated_at = NOW();

  -- For sell orders
  ELSE
    -- Get current holding details
    SELECT quantity, avg_price, total_invested 
    INTO current_quantity, current_avg_price, new_total_invested
    FROM portfolio
    WHERE user_id = user_id_param AND symbol = symbol_param;

    -- Check if user has enough shares
    IF current_quantity IS NULL OR current_quantity < quantity_param THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Insufficient shares',
        'required', quantity_param,
        'available', COALESCE(current_quantity, 0)
      );
    END IF;

    -- Calculate realized P&L
    realized_pnl := quantity_param * (price_param - current_avg_price);

    -- Update cash balance and user stats
    UPDATE users
    SET 
      cash_balance = cash_balance + total_value_param,
      total_trades = total_trades + 1,
      total_profit_loss = total_profit_loss + realized_pnl,
      last_trade_date = NOW(),
      updated_at = NOW()
    WHERE id = user_id_param;

    -- Update portfolio
    new_quantity := current_quantity - quantity_param;
    
    IF new_quantity = 0 THEN
      -- Remove from portfolio if selling all shares
      DELETE FROM portfolio
      WHERE user_id = user_id_param AND symbol = symbol_param;
    ELSE
      -- Update quantity and total invested proportionally
      new_total_invested := new_total_invested * (new_quantity::NUMERIC / current_quantity::NUMERIC);
      
      UPDATE portfolio
      SET 
        quantity = new_quantity,
        total_invested = new_total_invested,
        last_updated = NOW(),
        updated_at = NOW()
      WHERE user_id = user_id_param AND symbol = symbol_param;
    END IF;
  END IF;

  -- Insert transaction record
  INSERT INTO transactions (user_id, symbol, type, quantity, price, total_value, realized_pnl, sector, asset_type)
  VALUES (user_id_param, symbol_param, type_param, quantity_param, price_param, total_value_param, realized_pnl, sector_param, asset_type_param);

  -- Return success with transaction details
  RETURN jsonb_build_object(
    'success', true,
    'transaction', jsonb_build_object(
      'symbol', symbol_param,
      'type', type_param,
      'quantity', quantity_param,
      'price', price_param,
      'total_value', total_value_param,
      'realized_pnl', realized_pnl
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update achievement progress
CREATE OR REPLACE FUNCTION update_achievement_progress(
  user_id_param UUID,
  achievement_id_param TEXT,
  progress_param INTEGER,
  target_param INTEGER,
  progress_data_param JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
  current_progress INTEGER;
  was_completed BOOLEAN;
  result JSONB;
BEGIN
  -- Insert or update achievement progress
  INSERT INTO achievement_progress (user_id, achievement_id, current_progress, target_progress, progress_data)
  VALUES (user_id_param, achievement_id_param, progress_param, target_param, progress_data_param)
  ON CONFLICT (user_id, achievement_id) DO UPDATE SET
    current_progress = progress_param,
    target_progress = target_param,
    progress_data = progress_data_param,
    updated_at = NOW()
  RETURNING current_progress, is_completed INTO current_progress, was_completed;

  -- Check if achievement should be completed
  IF current_progress >= target_param AND NOT was_completed THEN
    UPDATE achievement_progress
    SET is_completed = true, updated_at = NOW()
    WHERE user_id = user_id_param AND achievement_id = achievement_id_param;
    
    RETURN jsonb_build_object(
      'success', true,
      'completed', true,
      'progress', current_progress,
      'target', target_param
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'completed', false,
    'progress', current_progress,
    'target', target_param
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to unlock achievement
CREATE OR REPLACE FUNCTION unlock_achievement(
  user_id_param UUID,
  achievement_id_param TEXT,
  title_param TEXT,
  description_param TEXT,
  category_param achievement_category,
  icon_param TEXT,
  color_param TEXT
) RETURNS JSONB AS $$
BEGIN
  -- Insert achievement if not already unlocked
  INSERT INTO user_achievements (user_id, achievement_id, achievement_title, achievement_description, achievement_category, icon_name, color_hex)
  VALUES (user_id_param, achievement_id_param, title_param, description_param, category_param, icon_param, color_param)
  ON CONFLICT (user_id, achievement_id) DO NOTHING;

  -- Mark progress as completed
  UPDATE achievement_progress
  SET is_completed = true, updated_at = NOW()
  WHERE user_id = user_id_param AND achievement_id = achievement_id_param;

  RETURN jsonb_build_object(
    'success', true,
    'unlocked', true,
    'achievement', jsonb_build_object(
      'id', achievement_id_param,
      'title', title_param,
      'description', description_param
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update leaderboard
CREATE OR REPLACE FUNCTION update_leaderboard() RETURNS VOID AS $$
BEGIN
  -- Update existing leaderboard entries and insert new ones
  INSERT INTO leaderboard (user_id, username, display_name, avatar_url, net_worth, total_pnl, total_pnl_percentage, total_trades, achievements_count)
  SELECT 
    u.id,
    COALESCE(u.username, u.email),
    u.display_name,
    u.avatar_url,
    COALESCE(u.cash_balance, 0) + COALESCE(portfolio_value.total_value, 0) as net_worth,
    COALESCE(u.total_profit_loss, 0) as total_pnl,
    CASE 
      WHEN COALESCE(portfolio_value.total_value, 0) > 0 
      THEN (COALESCE(u.total_profit_loss, 0) / COALESCE(portfolio_value.total_value, 1)) * 100
      ELSE 0
    END as total_pnl_percentage,
    COALESCE(u.total_trades, 0) as total_trades,
    COALESCE(achievements_count.count, 0) as achievements_count
  FROM users u
  LEFT JOIN (
    SELECT 
      p.user_id,
      SUM(p.quantity * COALESCE(mp.price, p.avg_price)) as total_value
    FROM portfolio p
    LEFT JOIN market_prices mp ON p.symbol = mp.symbol
    GROUP BY p.user_id
  ) portfolio_value ON u.id = portfolio_value.user_id
  LEFT JOIN (
    SELECT user_id, COUNT(*) as count
    FROM user_achievements
    GROUP BY user_id
  ) achievements_count ON u.id = achievements_count.user_id
  ON CONFLICT (user_id) DO UPDATE SET
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    avatar_url = EXCLUDED.avatar_url,
    previous_rank = leaderboard.rank,
    net_worth = EXCLUDED.net_worth,
    total_pnl = EXCLUDED.total_pnl,
    total_pnl_percentage = EXCLUDED.total_pnl_percentage,
    total_trades = EXCLUDED.total_trades,
    achievements_count = EXCLUDED.achievements_count,
    updated_at = NOW();

  -- Update ranks
  UPDATE leaderboard
  SET rank = rank_calc.rank
  FROM (
    SELECT user_id, ROW_NUMBER() OVER (ORDER BY net_worth DESC) as rank
    FROM leaderboard
  ) rank_calc
  WHERE leaderboard.user_id = rank_calc.user_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, username, display_name, created_at, last_login)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data ->> 'name',
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.created_at,
    NEW.last_sign_in_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user last login
CREATE OR REPLACE FUNCTION update_user_last_login() RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_login = NEW.last_sign_in_at
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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

-- Insert comprehensive market data with proper sectors
INSERT INTO market_prices (symbol, name, price, change_24h, change_percent_24h, type, sector, exchange, is_active) VALUES
-- Technology Stocks
('AAPL', 'Apple Inc.', 175.43, 2.15, 1.24, 'stock', 'Technology', 'NASDAQ', true),
('MSFT', 'Microsoft Corporation', 378.85, 4.23, 1.13, 'stock', 'Technology', 'NASDAQ', true),
('GOOGL', 'Alphabet Inc.', 138.25, -1.85, -1.32, 'stock', 'Technology', 'NASDAQ', true),
('AMZN', 'Amazon.com Inc.', 151.94, -2.41, -1.56, 'stock', 'Technology', 'NASDAQ', true),
('META', 'Meta Platforms Inc.', 298.35, 5.67, 1.94, 'stock', 'Technology', 'NASDAQ', true),
('TSLA', 'Tesla Inc.', 248.50, 12.35, 5.23, 'stock', 'Technology', 'NASDAQ', true),
('NVDA', 'NVIDIA Corporation', 876.34, 23.45, 2.75, 'stock', 'Technology', 'NASDAQ', true),
('NFLX', 'Netflix Inc.', 445.67, -8.23, -1.81, 'stock', 'Technology', 'NASDAQ', true),
('ADBE', 'Adobe Inc.', 567.89, 12.34, 2.22, 'stock', 'Technology', 'NASDAQ', true),
('CRM', 'Salesforce Inc.', 234.56, 6.78, 2.98, 'stock', 'Technology', 'NYSE', true),
('INTC', 'Intel Corporation', 45.32, -0.78, -1.69, 'stock', 'Technology', 'NASDAQ', true),
('CSCO', 'Cisco Systems Inc.', 48.91, 0.45, 0.93, 'stock', 'Technology', 'NASDAQ', true),
('ORCL', 'Oracle Corporation', 98.76, 2.34, 2.43, 'stock', 'Technology', 'NYSE', true),
('AMD', 'Advanced Micro Devices', 134.21, 4.56, 3.52, 'stock', 'Technology', 'NASDAQ', true),
('IBM', 'International Business Machines', 165.43, 1.23, 0.75, 'stock', 'Technology', 'NYSE', true),

-- Healthcare Stocks
('JNJ', 'Johnson & Johnson', 158.92, 1.45, 0.92, 'stock', 'Healthcare', 'NYSE', true),
('UNH', 'UnitedHealth Group', 512.67, 8.34, 1.65, 'stock', 'Healthcare', 'NYSE', true),
('PFE', 'Pfizer Inc.', 32.45, -0.56, -1.69, 'stock', 'Healthcare', 'NYSE', true),
('ABT', 'Abbott Laboratories', 98.76, 2.12, 2.19, 'stock', 'Healthcare', 'NYSE', true),
('TMO', 'Thermo Fisher Scientific', 567.89, 12.34, 2.22, 'stock', 'Healthcare', 'NYSE', true),
('LLY', 'Eli Lilly and Company', 789.12, 15.67, 2.03, 'stock', 'Healthcare', 'NYSE', true),
('ABBV', 'AbbVie Inc.', 145.67, 2.34, 1.63, 'stock', 'Healthcare', 'NYSE', true),
('MDT', 'Medtronic plc', 87.45, 1.23, 1.43, 'stock', 'Healthcare', 'NYSE', true),
('BMY', 'Bristol-Myers Squibb', 54.32, -0.78, -1.41, 'stock', 'Healthcare', 'NYSE', true),
('GILD', 'Gilead Sciences Inc.', 76.89, 1.45, 1.92, 'stock', 'Healthcare', 'NASDAQ', true),

-- Financial Stocks
('JPM', 'JPMorgan Chase & Co.', 145.67, 2.34, 1.63, 'stock', 'Financial', 'NYSE', true),
('BAC', 'Bank of America Corp.', 34.56, 0.78, 2.31, 'stock', 'Financial', 'NYSE', true),
('WFC', 'Wells Fargo & Company', 45.67, 1.23, 2.77, 'stock', 'Financial', 'NYSE', true),
('GS', 'Goldman Sachs Group Inc.', 387.45, 8.92, 2.36, 'stock', 'Financial', 'NYSE', true),
('MS', 'Morgan Stanley', 89.34, 2.45, 2.82, 'stock', 'Financial', 'NYSE', true),
('V', 'Visa Inc.', 234.56, 3.45, 1.49, 'stock', 'Financial', 'NYSE', true),
('MA', 'Mastercard Inc.', 456.78, 7.89, 1.76, 'stock', 'Financial', 'NYSE', true),
('AXP', 'American Express Company', 178.92, 3.45, 1.96, 'stock', 'Financial', 'NYSE', true),
('C', 'Citigroup Inc.', 56.78, 1.23, 2.21, 'stock', 'Financial', 'NYSE', true),
('BLK', 'BlackRock Inc.', 678.90, 12.34, 1.85, 'stock', 'Financial', 'NYSE', true),

-- Energy Stocks
('XOM', 'Exxon Mobil Corporation', 98.76, 2.34, 2.43, 'stock', 'Energy', 'NYSE', true),
('CVX', 'Chevron Corporation', 156.78, 3.45, 2.25, 'stock', 'Energy', 'NYSE', true),
('COP', 'ConocoPhillips', 123.45, 2.78, 2.30, 'stock', 'Energy', 'NYSE', true),
('EOG', 'EOG Resources Inc.', 134.56, 3.21, 2.44, 'stock', 'Energy', 'NYSE', true),
('SLB', 'Schlumberger Limited', 45.67, 1.23, 2.77, 'stock', 'Energy', 'NYSE', true),
('KMI', 'Kinder Morgan Inc.', 18.92, 0.34, 1.83, 'stock', 'Energy', 'NYSE', true),
('VLO', 'Valero Energy Corporation', 134.56, 2.78, 2.11, 'stock', 'Energy', 'NYSE', true),
('PSX', 'Phillips 66', 89.34, 1.89, 2.16, 'stock', 'Energy', 'NYSE', true),
('MPC', 'Marathon Petroleum Corporation', 167.89, 3.45, 2.09, 'stock', 'Energy', 'NYSE', true),
('OXY', 'Occidental Petroleum Corporation', 67.89, 1.78, 2.69, 'stock', 'Energy', 'NYSE', true),

-- Consumer Stocks
('WMT', 'Walmart Inc.', 156.78, 2.34, 1.52, 'stock', 'Consumer', 'NYSE', true),
('HD', 'Home Depot Inc.', 298.45, 4.67, 1.59, 'stock', 'Consumer', 'NYSE', true),
('PG', 'Procter & Gamble Co.', 145.67, 1.89, 1.31, 'stock', 'Consumer', 'NYSE', true),
('KO', 'Coca-Cola Company', 58.92, 0.78, 1.34, 'stock', 'Consumer', 'NYSE', true),
('PEP', 'PepsiCo Inc.', 167.89, 2.34, 1.41, 'stock', 'Consumer', 'NASDAQ', true),
('COST', 'Costco Wholesale Corporation', 678.90, 8.45, 1.26, 'stock', 'Consumer', 'NASDAQ', true),
('NKE', 'Nike Inc.', 98.76, 1.78, 1.83, 'stock', 'Consumer', 'NYSE', true),
('SBUX', 'Starbucks Corporation', 89.34, 1.45, 1.65, 'stock', 'Consumer', 'NASDAQ', true),
('MCD', 'McDonald''s Corporation', 267.89, 3.45, 1.31, 'stock', 'Consumer', 'NYSE', true),
('LOW', 'Lowe''s Companies Inc.', 234.56, 3.78, 1.64, 'stock', 'Consumer', 'NYSE', true),

-- ETFs
('SPY', 'SPDR S&P 500 ETF Trust', 436.92, 2.84, 0.65, 'etf', 'Broad Market', 'NYSE', true),
('QQQ', 'Invesco QQQ Trust', 375.29, 4.12, 1.11, 'etf', 'Technology', 'NASDAQ', true),
('IWM', 'iShares Russell 2000 ETF', 198.45, 2.34, 1.19, 'etf', 'Small Cap', 'NYSE', true),
('VTI', 'Vanguard Total Stock Market ETF', 234.56, 2.78, 1.20, 'etf', 'Broad Market', 'NYSE', true),
('EFA', 'iShares MSCI EAFE ETF', 76.89, 1.23, 1.63, 'etf', 'International', 'NYSE', true),
('VEA', 'Vanguard FTSE Developed Markets ETF', 45.67, 0.78, 1.74, 'etf', 'International', 'NYSE', true),
('VWO', 'Vanguard FTSE Emerging Markets ETF', 34.56, 0.89, 2.64, 'etf', 'Emerging Markets', 'NYSE', true),
('GLD', 'SPDR Gold Shares', 189.34, -1.23, -0.64, 'etf', 'Commodities', 'NYSE', true),
('SLV', 'iShares Silver Trust', 23.45, -0.34, -1.43, 'etf', 'Commodities', 'NYSE', true),
('TLT', 'iShares 20+ Year Treasury Bond ETF', 98.76, 1.23, 1.26, 'etf', 'Bonds', 'NYSE', true),

-- Cryptocurrencies
('BTC', 'Bitcoin', 67845.32, 1247.85, 1.87, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('ETH', 'Ethereum', 3456.78, -89.23, -2.52, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('BNB', 'Binance Coin', 598.47, 23.15, 4.02, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('ADA', 'Cardano', 0.456, 0.023, 5.31, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('SOL', 'Solana', 234.56, 12.34, 5.56, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('DOT', 'Polkadot', 12.34, 0.45, 3.79, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('AVAX', 'Avalanche', 45.67, 2.34, 5.41, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('LINK', 'Chainlink', 23.45, 1.23, 5.54, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('UNI', 'Uniswap', 8.92, 0.34, 3.96, 'crypto', 'Cryptocurrency', 'CRYPTO', true),
('MATIC', 'Polygon', 1.234, 0.089, 7.76, 'crypto', 'Cryptocurrency', 'CRYPTO', true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Create some initial achievement definitions (these will be loaded by the app)
COMMENT ON TABLE achievement_progress IS 'Tracks user progress towards achievements';
COMMENT ON TABLE user_achievements IS 'Stores unlocked achievements for users';
COMMENT ON TABLE user_settings IS 'Stores user preferences and settings';
COMMENT ON TABLE market_prices IS 'Cached market data with sectors for achievement tracking';
COMMENT ON TABLE leaderboard IS 'Public leaderboard with user rankings';

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Database schema created successfully!';
  RAISE NOTICE 'Total tables created: 8';
  RAISE NOTICE 'Total functions created: 6';
  RAISE NOTICE 'Total triggers created: 2';
  RAISE NOTICE 'Market data inserted: 70+ stocks, ETFs, and cryptocurrencies';
  RAISE NOTICE 'All RLS policies configured for security';
END $$;