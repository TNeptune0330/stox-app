-- Database Reset Script for Stox Trading App
-- This script completely removes the existing database and creates a fresh one
-- WARNING: This will delete ALL user data including portfolios, transactions, and achievements

-- First, drop all existing tables if they exist
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS portfolio CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS watchlist CASCADE;
DROP TABLE IF EXISTS market_data_cache CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS auth_profiles CASCADE;

-- Drop any indexes that might exist
DROP INDEX IF EXISTS idx_transactions_user_id;
DROP INDEX IF EXISTS idx_transactions_symbol;
DROP INDEX IF EXISTS idx_transactions_timestamp;
DROP INDEX IF EXISTS idx_portfolio_user_id;
DROP INDEX IF EXISTS idx_portfolio_symbol;
DROP INDEX IF EXISTS idx_user_achievements_user_id;
DROP INDEX IF EXISTS idx_user_achievements_achievement_id;
DROP INDEX IF EXISTS idx_watchlist_user_id;
DROP INDEX IF EXISTS idx_watchlist_symbol;
DROP INDEX IF EXISTS idx_market_data_cache_symbol;
DROP INDEX IF EXISTS idx_market_data_cache_timestamp;

-- Drop any sequences that might exist
DROP SEQUENCE IF EXISTS transactions_id_seq CASCADE;
DROP SEQUENCE IF EXISTS portfolio_id_seq CASCADE;
DROP SEQUENCE IF EXISTS achievements_id_seq CASCADE;
DROP SEQUENCE IF EXISTS user_achievements_id_seq CASCADE;
DROP SEQUENCE IF EXISTS watchlist_id_seq CASCADE;

-- Enable UUID extension for unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create auth_profiles table for user authentication
CREATE TABLE auth_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    raw_app_meta_data JSONB,
    raw_user_meta_data JSONB,
    is_super_admin BOOLEAN DEFAULT FALSE,
    role VARCHAR(255) DEFAULT 'authenticated'
);

-- Create portfolio table for user holdings
CREATE TABLE portfolio (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth_profiles(id) ON DELETE CASCADE,
    symbol VARCHAR(10) NOT NULL,
    quantity DECIMAL(15, 6) NOT NULL DEFAULT 0,
    avg_price DECIMAL(15, 2) NOT NULL DEFAULT 0,
    total_invested DECIMAL(15, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, symbol)
);

-- Create transactions table for trading history
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth_profiles(id) ON DELETE CASCADE,
    symbol VARCHAR(10) NOT NULL,
    transaction_type VARCHAR(4) NOT NULL CHECK (transaction_type IN ('BUY', 'SELL')),
    quantity DECIMAL(15, 6) NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    fees DECIMAL(15, 2) DEFAULT 0,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    market_value DECIMAL(15, 2),
    notes TEXT
);

-- Create achievements table for gamification
CREATE TABLE achievements (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    requirement_type VARCHAR(50) NOT NULL,
    requirement_value INTEGER NOT NULL,
    points INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_achievements table for tracking user progress
CREATE TABLE user_achievements (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth_profiles(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 0,
    is_unlocked BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, achievement_id)
);

-- Create watchlist table for user stock watchlists
CREATE TABLE watchlist (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth_profiles(id) ON DELETE CASCADE,
    symbol VARCHAR(10) NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    UNIQUE(user_id, symbol)
);

-- Create market_data_cache table for caching stock prices
CREATE TABLE market_data_cache (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(10) NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    change_amount DECIMAL(15, 2) DEFAULT 0,
    change_percent DECIMAL(8, 4) DEFAULT 0,
    volume BIGINT DEFAULT 0,
    market_cap BIGINT,
    pe_ratio DECIMAL(8, 2),
    dividend_yield DECIMAL(8, 4),
    week_52_high DECIMAL(15, 2),
    week_52_low DECIMAL(15, 2),
    day_high DECIMAL(15, 2),
    day_low DECIMAL(15, 2),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'finnhub'
);

-- Create user_settings table for app preferences
CREATE TABLE user_settings (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth_profiles(id) ON DELETE CASCADE,
    setting_key VARCHAR(100) NOT NULL,
    setting_value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, setting_key)
);

-- Create indexes for better performance
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_symbol ON transactions(symbol);
CREATE INDEX idx_transactions_timestamp ON transactions(timestamp);
CREATE INDEX idx_portfolio_user_id ON portfolio(user_id);
CREATE INDEX idx_portfolio_symbol ON portfolio(symbol);
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX idx_watchlist_user_id ON watchlist(user_id);
CREATE INDEX idx_watchlist_symbol ON watchlist(symbol);
CREATE INDEX idx_market_data_cache_symbol ON market_data_cache(symbol);
CREATE INDEX idx_market_data_cache_timestamp ON market_data_cache(last_updated);

-- Insert default achievements
INSERT INTO achievements (title, description, icon, category, requirement_type, requirement_value, points) VALUES
('First Trade', 'Complete your first stock trade', 'trending_up', 'trading', 'trades_count', 1, 100),
('Portfolio Builder', 'Hold 5 different stocks in your portfolio', 'account_balance_wallet', 'portfolio', 'unique_holdings', 5, 250),
('Profit Maker', 'Make your first $100 in profit', 'attach_money', 'earnings', 'total_profit', 10000, 300),
('Day Trader', 'Complete 10 trades in a single day', 'schedule', 'trading', 'daily_trades', 10, 400),
('Long Term Investor', 'Hold a stock for more than 30 days', 'access_time', 'strategy', 'holding_days', 30, 200),
('Market Explorer', 'Trade in 3 different market sectors', 'public', 'diversity', 'sectors_traded', 3, 350),
('Big Spender', 'Make a single trade worth $1000 or more', 'savings', 'trading', 'single_trade_value', 100000, 500),
('Consistent Trader', 'Trade for 7 consecutive days', 'repeat', 'consistency', 'consecutive_days', 7, 300),
('Watchlist Expert', 'Add 10 stocks to your watchlist', 'bookmark', 'research', 'watchlist_count', 10, 150),
('Profit Streaker', 'Make profitable trades for 5 consecutive trades', 'trending_up', 'performance', 'profit_streak', 5, 400);

-- Insert default user settings
-- These will be populated when users first use the app

-- Add RLS (Row Level Security) policies for data protection
ALTER TABLE auth_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE watchlist ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies to ensure users can only access their own data
CREATE POLICY "Users can view own profile" ON auth_profiles
    FOR ALL USING (id = auth.uid());

CREATE POLICY "Users can manage own portfolio" ON portfolio
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own transactions" ON transactions
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own achievements" ON user_achievements
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own watchlist" ON watchlist
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Users can manage own settings" ON user_settings
    FOR ALL USING (user_id = auth.uid());

-- Allow public read access to achievements table
CREATE POLICY "Anyone can view achievements" ON achievements
    FOR SELECT USING (true);

-- Allow public read access to market data cache
CREATE POLICY "Anyone can view market data" ON market_data_cache
    FOR SELECT USING (true);

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_portfolio_updated_at BEFORE UPDATE ON portfolio
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_auth_profiles_updated_at BEFORE UPDATE ON auth_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to automatically update portfolio when transactions occur
CREATE OR REPLACE FUNCTION update_portfolio_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
    -- For BUY transactions
    IF NEW.transaction_type = 'BUY' THEN
        INSERT INTO portfolio (user_id, symbol, quantity, avg_price, total_invested)
        VALUES (NEW.user_id, NEW.symbol, NEW.quantity, NEW.price, NEW.total_amount)
        ON CONFLICT (user_id, symbol)
        DO UPDATE SET
            quantity = portfolio.quantity + NEW.quantity,
            avg_price = (portfolio.total_invested + NEW.total_amount) / (portfolio.quantity + NEW.quantity),
            total_invested = portfolio.total_invested + NEW.total_amount,
            updated_at = NOW();
    
    -- For SELL transactions
    ELSIF NEW.transaction_type = 'SELL' THEN
        UPDATE portfolio
        SET 
            quantity = quantity - NEW.quantity,
            total_invested = CASE 
                WHEN quantity - NEW.quantity <= 0 THEN 0
                ELSE total_invested * ((quantity - NEW.quantity) / quantity)
            END,
            updated_at = NOW()
        WHERE user_id = NEW.user_id AND symbol = NEW.symbol;
        
        -- Remove portfolio entry if quantity becomes 0 or negative
        DELETE FROM portfolio 
        WHERE user_id = NEW.user_id AND symbol = NEW.symbol AND quantity <= 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for portfolio updates
CREATE TRIGGER trigger_update_portfolio_on_transaction
    AFTER INSERT ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_portfolio_on_transaction();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create demo user for testing (optional)
-- INSERT INTO auth_profiles (id, email, raw_user_meta_data) 
-- VALUES ('00000000-0000-0000-0000-000000000001', 'demo@stox.app', '{"name": "Demo User"}');

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Database reset completed successfully!';
    RAISE NOTICE 'Tables created: auth_profiles, portfolio, transactions, achievements, user_achievements, watchlist, market_data_cache, user_settings';
    RAISE NOTICE 'Default achievements inserted: % rows', (SELECT COUNT(*) FROM achievements);
    RAISE NOTICE 'RLS policies enabled for data security';
    RAISE NOTICE 'Triggers created for automatic updates';
END $$;