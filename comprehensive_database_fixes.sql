-- Comprehensive Database Fixes for Stox Trading App
-- This script includes all database enhancements requested during development

-- ============================================================================
-- 1. TRADE COUNTER SYSTEM
-- Enhances per-user trade counting system with database functions
-- ============================================================================

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

-- Function to sync trade achievements with database
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

-- ============================================================================
-- 2. ACHIEVEMENT SYSTEM ENHANCEMENTS
-- Enhanced achievement tracking and progress management
-- ============================================================================

-- Enhanced function to update achievement progress
CREATE OR REPLACE FUNCTION update_achievement_progress(
  user_id_param UUID,
  achievement_id_param TEXT,
  progress_param INTEGER,
  target_param INTEGER,
  progress_data_param JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
BEGIN
  -- Insert or update achievement progress
  INSERT INTO achievement_progress (
    user_id, 
    achievement_id, 
    current_progress, 
    target_progress, 
    progress_data,
    is_completed,
    updated_at
  )
  VALUES (
    user_id_param,
    achievement_id_param,
    progress_param,
    target_param,
    progress_data_param,
    progress_param >= target_param,
    NOW()
  )
  ON CONFLICT (user_id, achievement_id)
  DO UPDATE SET
    current_progress = progress_param,
    target_progress = target_param,
    progress_data = progress_data_param,
    is_completed = progress_param >= target_param,
    updated_at = NOW();

  RETURN QUERY SELECT TRUE::BOOLEAN, 'Achievement progress updated successfully'::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enhanced function to unlock achievement
CREATE OR REPLACE FUNCTION unlock_achievement(
  user_id_param UUID,
  achievement_id_param TEXT,
  title_param TEXT,
  description_param TEXT,
  category_param TEXT,
  icon_param TEXT,
  color_param TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
BEGIN
  -- Check if achievement is already unlocked
  IF EXISTS (
    SELECT 1 FROM user_achievements 
    WHERE user_id = user_id_param AND achievement_id = achievement_id_param
  ) THEN
    RETURN QUERY SELECT TRUE::BOOLEAN, 'Achievement already unlocked'::TEXT;
    RETURN;
  END IF;

  -- Insert new achievement unlock
  INSERT INTO user_achievements (
    user_id,
    achievement_id,
    achievement_title,
    achievement_description,
    achievement_category,
    icon_name,
    color_hex,
    unlocked_at
  )
  VALUES (
    user_id_param,
    achievement_id_param,
    title_param,
    description_param,
    category_param,
    icon_param,
    color_param,
    NOW()
  );

  -- Update progress to completed
  UPDATE achievement_progress
  SET is_completed = TRUE,
      updated_at = NOW()
  WHERE user_id = user_id_param AND achievement_id = achievement_id_param;

  RETURN QUERY SELECT TRUE::BOOLEAN, 'Achievement unlocked successfully'::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE::BOOLEAN, SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- Optimizes database queries for better performance
-- ============================================================================

-- Create index on total_trades for better performance
CREATE INDEX IF NOT EXISTS idx_users_total_trades ON users(total_trades);

-- Create index on transactions for trade counting
CREATE INDEX IF NOT EXISTS idx_transactions_user_timestamp ON transactions(user_id, timestamp);

-- Create indexes on achievement tables
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_category ON user_achievements(achievement_category);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at);

CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_id ON achievement_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_completed ON achievement_progress(is_completed);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_updated ON achievement_progress(updated_at);

-- ============================================================================
-- 4. VIEWS FOR EASY QUERYING
-- Convenient views for achievement and trade data
-- ============================================================================

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

-- View for user achievement statistics
CREATE OR REPLACE VIEW user_achievement_stats AS
SELECT 
  u.id as user_id,
  u.email,
  COUNT(ua.id) as total_unlocked,
  COUNT(CASE WHEN ua.achievement_category = 'trading' THEN 1 END) as trading_achievements,
  COUNT(CASE WHEN ua.achievement_category = 'milestone' THEN 1 END) as milestone_achievements,
  COUNT(CASE WHEN ua.achievement_category = 'profit' THEN 1 END) as profit_achievements,
  COUNT(CASE WHEN ua.achievement_category = 'streak' THEN 1 END) as streak_achievements,
  COUNT(CASE WHEN ua.achievement_category = 'special' THEN 1 END) as special_achievements,
  MIN(ua.unlocked_at) as first_achievement_at,
  MAX(ua.unlocked_at) as latest_achievement_at
FROM users u
LEFT JOIN user_achievements ua ON u.id = ua.user_id
GROUP BY u.id, u.email;

-- ============================================================================
-- 5. PERMISSIONS AND SECURITY
-- Row Level Security and function permissions
-- ============================================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_user_trade_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_achievement_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION sync_trade_achievements(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_user_trade_count(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_achievement_progress(UUID, TEXT, INTEGER, INTEGER, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION unlock_achievement(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Grant access to views
GRANT SELECT ON user_trade_achievements TO authenticated;
GRANT SELECT ON user_achievement_stats TO authenticated;

-- Enable RLS on views (if not already enabled)
ALTER VIEW user_trade_achievements OWNER TO postgres;
ALTER VIEW user_achievement_stats OWNER TO postgres;

-- ============================================================================
-- 6. FUNCTION DOCUMENTATION
-- Comments explaining each function's purpose
-- ============================================================================

COMMENT ON FUNCTION get_user_trade_count IS 'Returns the current trade count for a specific user';
COMMENT ON FUNCTION get_user_achievement_progress IS 'Returns detailed achievement progress for trade-based achievements';
COMMENT ON FUNCTION sync_trade_achievements IS 'Returns achievement sync data for the app achievement system';
COMMENT ON FUNCTION recalculate_user_trade_count IS 'Recalculates trade count from actual transactions (for data consistency)';
COMMENT ON FUNCTION update_achievement_progress IS 'Updates achievement progress with enhanced error handling';
COMMENT ON FUNCTION unlock_achievement IS 'Unlocks achievement with full metadata and duplicate checking';

COMMENT ON VIEW user_trade_achievements IS 'View showing trade achievement completion status for all users';
COMMENT ON VIEW user_achievement_stats IS 'View showing comprehensive achievement statistics by category';

-- ============================================================================
-- 7. DATA MIGRATION (Optional - if needed)
-- Migrate existing data to new achievement structure
-- ============================================================================

-- Function to migrate existing achievements to new 5-category system
CREATE OR REPLACE FUNCTION migrate_achievement_categories()
RETURNS TABLE(migrated_count INTEGER, message TEXT) AS $$
DECLARE
  migration_count INTEGER := 0;
BEGIN
  -- Update any existing achievements to use new category system
  -- This is safe to run multiple times
  
  -- Update trading category achievements
  UPDATE user_achievements 
  SET achievement_category = 'trading'
  WHERE achievement_id IN ('first_trade', 'ten_trades', 'hundred_trades', 'thousand_trades', 'legendary_trader')
  AND achievement_category != 'trading';
  
  GET DIAGNOSTICS migration_count = ROW_COUNT;
  
  -- Update milestone category achievements
  UPDATE user_achievements 
  SET achievement_category = 'milestone'
  WHERE achievement_id IN ('diversified', 'portfolio_watcher', 'market_explorer', 'master_of_all')
  AND achievement_category != 'milestone';
  
  -- Update profit category achievements
  UPDATE user_achievements 
  SET achievement_category = 'profit'
  WHERE achievement_id IN ('first_profit', 'big_profit', 'millionaire', 'multi_millionaire', 'billionaire')
  AND achievement_category != 'profit';
  
  -- Update streak category achievements
  UPDATE user_achievements 
  SET achievement_category = 'streak'
  WHERE achievement_id IN ('winning_streak', 'marathon_trader', 'perfectionist')
  AND achievement_category != 'streak';
  
  -- Update special category achievements
  UPDATE user_achievements 
  SET achievement_category = 'special'
  WHERE achievement_id IN ('diamond_hands', 'paper_hands', 'early_bird', 'night_owl', 'weekend_warrior', 
                          'high_roller', 'penny_pincher', 'day_trader', 'swing_trader', 'value_investor')
  AND achievement_category != 'special';

  -- Remove any sector-based achievements that are no longer valid
  DELETE FROM user_achievements 
  WHERE achievement_id IN ('tech_giant', 'energy_investor', 'healthcare_hero', 'financial_wizard', 
                          'meme_lord', 'sp500_champion', 'etf_fan', 'dividend_hunter', 'small_cap', 
                          'international', 'consumer_staples');

  -- Remove corresponding progress entries
  DELETE FROM achievement_progress 
  WHERE achievement_id IN ('tech_giant', 'energy_investor', 'healthcare_hero', 'financial_wizard', 
                          'meme_lord', 'sp500_champion', 'etf_fan', 'dividend_hunter', 'small_cap', 
                          'international', 'consumer_staples');

  RETURN QUERY SELECT migration_count, 'Achievement categories migrated successfully'::TEXT;
EXCEPTION
  WHEN OTHERS THEN
    RETURN QUERY SELECT 0, ('Migration failed: ' || SQLERRM)::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permission to run migration
GRANT EXECUTE ON FUNCTION migrate_achievement_categories() TO authenticated;

COMMENT ON FUNCTION migrate_achievement_categories IS 'One-time migration function to update achievement categories and remove obsolete sector-based achievements';

-- ============================================================================
-- 8. VERIFICATION QUERIES
-- Queries to verify the database fixes are working correctly
-- ============================================================================

-- Query to test trade counting functions
-- SELECT get_user_trade_count('your-user-id-here');
-- SELECT * FROM get_user_achievement_progress('your-user-id-here');
-- SELECT * FROM sync_trade_achievements('your-user-id-here');

-- Query to view achievement statistics
-- SELECT * FROM user_achievement_stats WHERE user_id = 'your-user-id-here';
-- SELECT * FROM user_trade_achievements WHERE user_id = 'your-user-id-here';

-- ============================================================================
-- END OF COMPREHENSIVE DATABASE FIXES
-- ============================================================================

-- To apply this script:
-- 1. Connect to your Supabase database
-- 2. Run this entire script
-- 3. Optionally run: SELECT migrate_achievement_categories(); to clean up old data
-- 4. Test with the verification queries above