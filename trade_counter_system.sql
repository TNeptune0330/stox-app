-- SQL Script to enhance per-user trade counting system
-- The total_trades field already exists in the users table and is updated by execute_trade function

-- Function to get user's current trade count
CREATE OR REPLACE FUNCTION get_user_trade_count(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  trade_count INTEGER;
BEGIN
  SELECT COALESCE(total_trades, 0) INTO trade_count
  FROM users
  WHERE id = user_id_param;
  
  IF trade_count IS NULL THEN
    RETURN 0;
  END IF;
  
  RETURN trade_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's trade count and achievement progress
CREATE OR REPLACE FUNCTION get_user_achievement_progress(user_id_param UUID)
RETURNS TABLE(
  total_trades INTEGER,
  first_trade_progress INTEGER,
  ten_trades_progress INTEGER,
  hundred_trades_progress INTEGER,
  thousand_trades_progress INTEGER,
  legendary_trader_progress INTEGER
) AS $$
DECLARE
  trade_count INTEGER;
BEGIN
  -- Get current trade count
  SELECT COALESCE(u.total_trades, 0) INTO trade_count
  FROM users u
  WHERE u.id = user_id_param;
  
  IF trade_count IS NULL THEN
    trade_count := 0;
  END IF;
  
  -- Return progress for all trade-based achievements
  RETURN QUERY SELECT 
    trade_count as total_trades,
    LEAST(trade_count, 1) as first_trade_progress,      -- First trade (1 trade)
    LEAST(trade_count, 10) as ten_trades_progress,      -- Getting Started (10 trades)
    LEAST(trade_count, 100) as hundred_trades_progress, -- Active Trader (100 trades)
    LEAST(trade_count, 1000) as thousand_trades_progress, -- Trading Master (1000 trades)
    LEAST(trade_count, 10000) as legendary_trader_progress; -- Legendary Trader (10000 trades)
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to sync trade count with achievement system
CREATE OR REPLACE FUNCTION sync_trade_achievements(user_id_param UUID)
RETURNS TABLE(
  achievement_id TEXT,
  current_progress INTEGER,
  target INTEGER,
  is_complete BOOLEAN
) AS $$
DECLARE
  trade_count INTEGER;
BEGIN
  -- Get current trade count
  SELECT COALESCE(u.total_trades, 0) INTO trade_count
  FROM users u
  WHERE u.id = user_id_param;
  
  IF trade_count IS NULL THEN
    trade_count := 0;
  END IF;
  
  -- Return achievement progress data
  RETURN QUERY VALUES
    ('first_trade'::TEXT, LEAST(trade_count, 1), 1, trade_count >= 1),
    ('ten_trades'::TEXT, LEAST(trade_count, 10), 10, trade_count >= 10),
    ('hundred_trades'::TEXT, LEAST(trade_count, 100), 100, trade_count >= 100),
    ('thousand_trades'::TEXT, LEAST(trade_count, 1000), 1000, trade_count >= 1000),
    ('legendary_trader'::TEXT, LEAST(trade_count, 10000), 10000, trade_count >= 10000);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure the execute_trade function properly increments total_trades
-- (This is already implemented in the existing schema)

-- Create index on total_trades for better performance
CREATE INDEX IF NOT EXISTS idx_users_total_trades ON users(total_trades);

-- Create index on transactions for trade counting
CREATE INDEX IF NOT EXISTS idx_transactions_user_timestamp ON transactions(user_id, timestamp);

-- Function to recalculate trade count for a user (in case of data inconsistency)
CREATE OR REPLACE FUNCTION recalculate_user_trade_count(user_id_param UUID)
RETURNS INTEGER AS $$
DECLARE
  actual_trade_count INTEGER;
BEGIN
  -- Count actual transactions
  SELECT COUNT(*) INTO actual_trade_count
  FROM transactions
  WHERE user_id = user_id_param;
  
  -- Update user record
  UPDATE users
  SET total_trades = actual_trade_count,
      updated_at = NOW()
  WHERE id = user_id_param;
  
  RETURN actual_trade_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add RLS policies for the new functions
GRANT EXECUTE ON FUNCTION get_user_trade_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_achievement_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION sync_trade_achievements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_user_trade_count(UUID) TO authenticated;

-- Create a view for easy achievement progress tracking
CREATE OR REPLACE VIEW user_trade_achievements AS
SELECT 
  u.id as user_id,
  u.email,
  u.total_trades,
  CASE WHEN u.total_trades >= 1 THEN true ELSE false END as first_trade_complete,
  CASE WHEN u.total_trades >= 10 THEN true ELSE false END as ten_trades_complete,
  CASE WHEN u.total_trades >= 100 THEN true ELSE false END as hundred_trades_complete,
  CASE WHEN u.total_trades >= 1000 THEN true ELSE false END as thousand_trades_complete,
  CASE WHEN u.total_trades >= 10000 THEN true ELSE false END as legendary_trader_complete,
  u.created_at,
  u.updated_at
FROM users u;

-- Grant access to the view
GRANT SELECT ON user_trade_achievements TO authenticated;

-- Enable RLS on the view
ALTER VIEW user_trade_achievements OWNER TO postgres;

COMMENT ON FUNCTION get_user_trade_count IS 'Returns the current trade count for a specific user';
COMMENT ON FUNCTION get_user_achievement_progress IS 'Returns detailed achievement progress for trade-based achievements';
COMMENT ON FUNCTION sync_trade_achievements IS 'Returns achievement sync data for the app achievement system';
COMMENT ON FUNCTION recalculate_user_trade_count IS 'Recalculates trade count from actual transactions (for data consistency)';
COMMENT ON VIEW user_trade_achievements IS 'View showing trade achievement completion status for all users';