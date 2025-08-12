-- Stox App Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor

-- Create custom types
CREATE TYPE trade_type AS ENUM ('buy', 'sell');
CREATE TYPE asset_type AS ENUM ('stock', 'etf', 'crypto');
CREATE TYPE theme_type AS ENUM ('light', 'dark', 'green', 'blue');

-- Users table (extends auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),
  email TEXT NOT NULL,
  username TEXT UNIQUE,
  avatar_url TEXT,
  color_theme theme_type DEFAULT 'light',
  cash_balance NUMERIC DEFAULT 10000.00,
  total_trades INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Portfolio holdings table
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

-- Transaction history table
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  symbol TEXT NOT NULL,
  type trade_type NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price NUMERIC NOT NULL CHECK (price > 0),
  total_value NUMERIC NOT NULL CHECK (total_value > 0),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Market prices cache table
CREATE TABLE market_prices (
  symbol TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC NOT NULL CHECK (price > 0),
  change_24h NUMERIC,
  change_percent_24h NUMERIC,
  type asset_type NOT NULL,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Leaderboard table
CREATE TABLE leaderboard (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  net_worth NUMERIC NOT NULL DEFAULT 0,
  total_pnl NUMERIC NOT NULL DEFAULT 0,
  total_pnl_percentage NUMERIC NOT NULL DEFAULT 0,
  rank INTEGER,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Achievements table
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  achievement_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon TEXT NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_portfolio_user_id ON portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON portfolio(symbol);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_symbol ON transactions(symbol);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_market_prices_type ON market_prices(type);
CREATE INDEX idx_market_prices_updated ON market_prices(last_updated);
CREATE INDEX idx_leaderboard_rank ON leaderboard(rank);
CREATE INDEX idx_achievements_user_id ON achievements(user_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can read own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

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

-- RLS Policies for leaderboard (public read)
CREATE POLICY "Anyone can read leaderboard" ON leaderboard
  FOR SELECT USING (true);

CREATE POLICY "Users can update own leaderboard entry" ON leaderboard
  FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for achievements
CREATE POLICY "Users can read own achievements" ON achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own achievements" ON achievements
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
  total_value_param NUMERIC
) RETURNS VOID AS $$
DECLARE
  current_balance NUMERIC;
  current_quantity INTEGER;
  new_quantity INTEGER;
  new_avg_price NUMERIC;
BEGIN
  -- Get current cash balance
  SELECT cash_balance INTO current_balance
  FROM users
  WHERE id = user_id_param;

  -- For buy orders
  IF type_param = 'buy' THEN
    -- Check if user has enough cash
    IF current_balance < total_value_param THEN
      RAISE EXCEPTION 'Insufficient funds';
    END IF;

    -- Update cash balance
    UPDATE users
    SET cash_balance = cash_balance - total_value_param,
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
      RAISE EXCEPTION 'Insufficient shares';
    END IF;

    -- Update cash balance
    UPDATE users
    SET cash_balance = cash_balance + total_value_param,
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
  INSERT INTO transactions (user_id, symbol, type, quantity, price, total_value)
  VALUES (user_id_param, symbol_param, type_param, quantity_param, price_param, total_value_param);

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update leaderboard
CREATE OR REPLACE FUNCTION update_leaderboard() RETURNS VOID AS $$
BEGIN
  -- Clear existing leaderboard
  DELETE FROM leaderboard;

  -- Calculate and insert new leaderboard data
  INSERT INTO leaderboard (user_id, username, net_worth, total_pnl, total_pnl_percentage)
  SELECT 
    u.id,
    COALESCE(u.username, u.email),
    COALESCE(u.cash_balance, 0) + COALESCE(portfolio_value.total_value, 0) as net_worth,
    COALESCE(portfolio_value.total_pnl, 0) as total_pnl,
    CASE 
      WHEN COALESCE(portfolio_value.total_value, 0) > 0 
      THEN (COALESCE(portfolio_value.total_pnl, 0) / COALESCE(portfolio_value.total_value, 1)) * 100
      ELSE 0
    END as total_pnl_percentage
  FROM users u
  LEFT JOIN (
    SELECT 
      p.user_id,
      SUM(p.quantity * mp.price) as total_value,
      SUM(p.quantity * (mp.price - p.avg_price)) as total_pnl
    FROM portfolio p
    JOIN market_prices mp ON p.symbol = mp.symbol
    GROUP BY p.user_id
  ) portfolio_value ON u.id = portfolio_value.user_id
  ORDER BY net_worth DESC;

  -- Update ranks
  UPDATE leaderboard
  SET rank = rank_calc.rank
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY net_worth DESC) as rank
    FROM leaderboard
  ) rank_calc
  WHERE leaderboard.id = rank_calc.id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (id, email, username, created_at, last_login)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data ->> 'name',
    NEW.created_at,
    NEW.last_sign_in_at
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create user profile on signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update user last login
CREATE OR REPLACE FUNCTION update_user_last_login() RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_login = NEW.last_sign_in_at
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update last login
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION update_user_last_login();

-- Insert some sample market data
INSERT INTO market_prices (symbol, name, price, change_24h, change_percent_24h, type) VALUES
('AAPL', 'Apple Inc.', 175.43, 2.15, 1.24, 'stock'),
('GOOGL', 'Alphabet Inc.', 138.25, -1.85, -1.32, 'stock'),
('MSFT', 'Microsoft Corporation', 378.85, 4.23, 1.13, 'stock'),
('AMZN', 'Amazon.com Inc.', 151.94, -2.41, -1.56, 'stock'),
('TSLA', 'Tesla Inc.', 248.50, 12.35, 5.23, 'stock'),
('SPY', 'SPDR S&P 500 ETF Trust', 436.92, 2.84, 0.65, 'etf'),
('QQQ', 'Invesco QQQ Trust', 375.29, 4.12, 1.11, 'etf'),
('BTC', 'Bitcoin', 67845.32, 1247.85, 1.87, 'crypto'),
('ETH', 'Ethereum', 3456.78, -89.23, -2.52, 'crypto'),
('BNB', 'Binance Coin', 598.47, 23.15, 4.02, 'crypto');

-- Create a cron job to update leaderboard every hour (requires pg_cron extension)
-- SELECT cron.schedule('update-leaderboard', '0 * * * *', 'SELECT update_leaderboard();');

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;