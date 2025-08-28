-- Final Schema Setup Script
-- Your schema already has most columns, this adds indexes, constraints, and populates metadata

-- ============================================================================
-- 1. ADD UNIQUE CONSTRAINTS (Prevent Duplicate Achievements)
-- ============================================================================

-- Ensure unique achievement per user (if not already exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'user_achievements_user_achievement_unique' 
    AND table_name = 'user_achievements'
  ) THEN
    ALTER TABLE public.user_achievements 
    ADD CONSTRAINT user_achievements_user_achievement_unique 
    UNIQUE (user_id, achievement_id);
  END IF;
END $$;

-- Ensure unique progress per user per achievement (if not already exists)  
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'achievement_progress_user_achievement_unique' 
    AND table_name = 'achievement_progress'
  ) THEN
    ALTER TABLE public.achievement_progress 
    ADD CONSTRAINT achievement_progress_user_achievement_unique 
    UNIQUE (user_id, achievement_id);
  END IF;
END $$;

-- ============================================================================
-- 2. CREATE PERFORMANCE INDEXES
-- ============================================================================

-- Achievement table indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_category ON public.user_achievements(achievement_category);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON public.user_achievements(unlocked_at);

-- Achievement progress indexes
CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_id ON public.achievement_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_completed ON public.achievement_progress(is_completed);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_updated ON public.achievement_progress(updated_at);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_achievement ON public.achievement_progress(user_id, achievement_id);

-- User and transaction indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_total_trades ON public.users(total_trades);
CREATE INDEX IF NOT EXISTS idx_transactions_user_timestamp ON public.transactions(user_id, timestamp);

-- ============================================================================
-- 3. POPULATE EXISTING ACHIEVEMENT DATA WITH METADATA
-- ============================================================================

-- Update existing user_achievements with metadata (safe to run multiple times)
UPDATE public.user_achievements SET 
  achievement_category = CASE 
    WHEN achievement_id IN ('first_trade', 'ten_trades', 'hundred_trades', 'thousand_trades', 'legendary_trader') THEN 'trading'
    WHEN achievement_id IN ('diversified', 'portfolio_watcher', 'market_explorer', 'master_of_all') THEN 'milestone' 
    WHEN achievement_id IN ('first_profit', 'big_profit', 'millionaire', 'multi_millionaire', 'billionaire') THEN 'profit'
    WHEN achievement_id IN ('winning_streak', 'marathon_trader', 'perfectionist') THEN 'streak'
    WHEN achievement_id IN ('diamond_hands', 'paper_hands', 'early_bird', 'night_owl', 'weekend_warrior', 
                           'high_roller', 'penny_pincher', 'day_trader', 'swing_trader', 'value_investor') THEN 'special'
    ELSE 'special'
  END,
  achievement_title = CASE achievement_id
    -- Trading achievements
    WHEN 'first_trade' THEN 'First Steps'
    WHEN 'ten_trades' THEN 'Getting Started' 
    WHEN 'hundred_trades' THEN 'Active Trader'
    WHEN 'thousand_trades' THEN 'Trading Master'
    WHEN 'legendary_trader' THEN 'Legendary Trader'
    -- Milestone achievements
    WHEN 'diversified' THEN 'Diversified'
    WHEN 'portfolio_watcher' THEN 'Portfolio Watcher'
    WHEN 'market_explorer' THEN 'Market Explorer'
    WHEN 'master_of_all' THEN 'Master of All'
    -- Profit achievements
    WHEN 'first_profit' THEN 'In the Green'
    WHEN 'big_profit' THEN 'Big Winner'
    WHEN 'millionaire' THEN 'Millionaire'
    WHEN 'multi_millionaire' THEN 'Multi-Millionaire'
    WHEN 'billionaire' THEN 'Billionaire'
    -- Streak achievements
    WHEN 'winning_streak' THEN 'Hot Streak'
    WHEN 'marathon_trader' THEN 'Marathon Trader'
    WHEN 'perfectionist' THEN 'Perfectionist'
    -- Special achievements
    WHEN 'diamond_hands' THEN 'Diamond Hands'
    WHEN 'paper_hands' THEN 'Paper Hands'
    WHEN 'early_bird' THEN 'Early Bird'
    WHEN 'night_owl' THEN 'Night Owl'
    WHEN 'weekend_warrior' THEN 'Weekend Warrior'
    WHEN 'high_roller' THEN 'High Roller'
    WHEN 'penny_pincher' THEN 'Penny Pincher'
    WHEN 'day_trader' THEN 'Day Trader'
    WHEN 'swing_trader' THEN 'Swing Trader'
    WHEN 'value_investor' THEN 'Value Investor'
    ELSE achievement_id
  END,
  achievement_description = CASE achievement_id
    -- Trading achievements
    WHEN 'first_trade' THEN 'Complete your first trade'
    WHEN 'ten_trades' THEN 'Complete 10 trades'
    WHEN 'hundred_trades' THEN 'Complete 100 trades'
    WHEN 'thousand_trades' THEN 'Complete 1,000 trades'
    WHEN 'legendary_trader' THEN 'Complete 10,000 trades'
    -- Milestone achievements
    WHEN 'diversified' THEN 'Hold 10 different assets'
    WHEN 'portfolio_watcher' THEN 'Check your portfolio 10 times'
    WHEN 'market_explorer' THEN 'Browse the market 25 times'
    WHEN 'master_of_all' THEN 'Unlock all other achievements'
    -- Profit achievements
    WHEN 'first_profit' THEN 'Make your first $1,000 profit'
    WHEN 'big_profit' THEN 'Reach $25,000 net worth'
    WHEN 'millionaire' THEN 'Reach $1,000,000 net worth'
    WHEN 'multi_millionaire' THEN 'Reach $10,000,000 net worth'
    WHEN 'billionaire' THEN 'Reach $1,000,000,000 net worth'
    -- Streak achievements
    WHEN 'winning_streak' THEN '5 profitable trades in a row'
    WHEN 'marathon_trader' THEN 'Trade for 7 consecutive days'
    WHEN 'perfectionist' THEN '10 profitable trades in a row'
    -- Special achievements
    WHEN 'diamond_hands' THEN 'Hold a position for 30 days'
    WHEN 'paper_hands' THEN 'Sell a position within 1 hour'
    WHEN 'early_bird' THEN 'Make a trade before 9 AM'
    WHEN 'night_owl' THEN 'Make a trade after 10 PM'
    WHEN 'weekend_warrior' THEN 'Make 5 trades on weekends'
    WHEN 'high_roller' THEN 'Make a single trade worth $50,000'
    WHEN 'penny_pincher' THEN 'Buy 1,000 shares of a stock under $5'
    WHEN 'day_trader' THEN 'Buy and sell the same stock on the same day'
    WHEN 'swing_trader' THEN 'Hold positions for 2-10 days'
    WHEN 'value_investor' THEN 'Hold a position for 90+ days'
    ELSE 'Achievement unlocked'
  END,
  icon_name = CASE achievement_id
    -- Trading achievements (Material Icons codepoints)
    WHEN 'first_trade' THEN '983555' -- Icons.trending_up
    WHEN 'ten_trades' THEN '983716' -- Icons.show_chart
    WHEN 'hundred_trades' THEN '983858' -- Icons.timeline
    WHEN 'thousand_trades' THEN '57404' -- Icons.auto_graph
    WHEN 'legendary_trader' THEN '59644' -- Icons.military_tech
    -- Milestone achievements
    WHEN 'diversified' THEN '983427' -- Icons.scatter_plot
    WHEN 'portfolio_watcher' THEN '59064' -- Icons.visibility
    WHEN 'market_explorer' THEN '57658' -- Icons.explore
    WHEN 'master_of_all' THEN '58086' -- Icons.emoji_events
    -- Profit achievements
    WHEN 'first_profit' THEN '57673' -- Icons.attach_money
    WHEN 'big_profit' THEN '57669' -- Icons.diamond
    WHEN 'millionaire' THEN '59644' -- Icons.military_tech
    WHEN 'multi_millionaire' THEN '59836' -- Icons.star
    WHEN 'billionaire' THEN '57404' -- Icons.auto_awesome
    -- Streak achievements
    WHEN 'winning_streak' THEN '58614' -- Icons.local_fire_department
    WHEN 'marathon_trader' THEN '983325' -- Icons.run_circle
    WHEN 'perfectionist' THEN '59836' -- Icons.star_rate
    -- Special achievements
    WHEN 'diamond_hands' THEN '983427' -- Icons.diamond_outlined
    WHEN 'paper_hands' THEN '58297' -- Icons.flash_on
    WHEN 'early_bird' THEN '59991' -- Icons.wb_sunny
    WHEN 'night_owl' THEN '59159' -- Icons.nightlight_round
    WHEN 'weekend_warrior' THEN '59991' -- Icons.weekend
    WHEN 'high_roller' THEN '57427' -- Icons.casino
    WHEN 'penny_pincher' THEN '58736' -- Icons.savings
    WHEN 'day_trader' THEN '57404' -- Icons.flash_auto
    WHEN 'swing_trader' THEN '983858' -- Icons.trending_neutral
    WHEN 'value_investor' THEN '58835' -- Icons.schedule
    ELSE '57404'
  END,
  color_hex = CASE achievement_id
    -- Trading achievements
    WHEN 'first_trade' THEN '#27ae60'
    WHEN 'ten_trades' THEN '#3498db'
    WHEN 'hundred_trades' THEN '#9b59b6'
    WHEN 'thousand_trades' THEN '#f39c12'
    WHEN 'legendary_trader' THEN '#8e44ad'
    -- Milestone achievements
    WHEN 'diversified' THEN '#16a085'
    WHEN 'portfolio_watcher' THEN '#3498db'
    WHEN 'market_explorer' THEN '#9b59b6'
    WHEN 'master_of_all' THEN '#f39c12'
    -- Profit achievements
    WHEN 'first_profit' THEN '#27ae60'
    WHEN 'big_profit' THEN '#e74c3c'
    WHEN 'millionaire' THEN '#f39c12'
    WHEN 'multi_millionaire' THEN '#8e44ad'
    WHEN 'billionaire' THEN '#e74c3c'
    -- Streak achievements
    WHEN 'winning_streak' THEN '#e74c3c'
    WHEN 'marathon_trader' THEN '#9b59b6'
    WHEN 'perfectionist' THEN '#f39c12'
    -- Special achievements
    WHEN 'diamond_hands' THEN '#3498db'
    WHEN 'paper_hands' THEN '#e67e22'
    WHEN 'early_bird' THEN '#f39c12'
    WHEN 'night_owl' THEN '#9b59b6'
    WHEN 'weekend_warrior' THEN '#059669'
    WHEN 'high_roller' THEN '#dc2626'
    WHEN 'penny_pincher' THEN '#059669'
    WHEN 'day_trader' THEN '#f39c12'
    WHEN 'swing_trader' THEN '#3498db'
    WHEN 'value_investor' THEN '#27ae60'
    ELSE '#3498db'
  END
WHERE 
  achievement_category IS NULL OR 
  achievement_title IS NULL OR 
  achievement_description IS NULL OR 
  icon_name IS NULL OR 
  color_hex IS NULL;

-- Update achievement_progress completion status
UPDATE public.achievement_progress 
SET is_completed = (current_progress >= target_progress)
WHERE is_completed IS NULL OR is_completed = false;

-- ============================================================================
-- 4. REMOVE UNUSED TABLES AND COLUMNS
-- ============================================================================

-- Drop the market_prices table since it's no longer needed
DROP TABLE IF EXISTS public.market_prices CASCADE;

-- Remove sector-related columns from users table (no longer needed after removing sector achievements)
ALTER TABLE public.users DROP COLUMN IF EXISTS sectors_traded;
ALTER TABLE public.users DROP COLUMN IF EXISTS asset_types_traded;

-- Remove other unused tracking columns
ALTER TABLE public.users DROP COLUMN IF EXISTS months_active;
ALTER TABLE public.users DROP COLUMN IF EXISTS total_app_opens;
ALTER TABLE public.users DROP COLUMN IF EXISTS total_screen_time_minutes;
ALTER TABLE public.users DROP COLUMN IF EXISTS max_single_day_gain;
ALTER TABLE public.users DROP COLUMN IF EXISTS max_single_day_loss;

-- ============================================================================
-- 5. CLEAN UP OLD SECTOR-BASED ACHIEVEMENTS
-- ============================================================================

-- Remove any old sector-based achievements that are no longer valid
DELETE FROM public.user_achievements 
WHERE achievement_id IN (
  'tech_giant', 'energy_investor', 'healthcare_hero', 'financial_wizard', 
  'meme_lord', 'sp500_champion', 'etf_fan', 'dividend_hunter', 'small_cap', 
  'international', 'consumer_staples', 'sector_rotator'
);

-- Remove corresponding progress entries
DELETE FROM public.achievement_progress 
WHERE achievement_id IN (
  'tech_giant', 'energy_investor', 'healthcare_hero', 'financial_wizard', 
  'meme_lord', 'sp500_champion', 'etf_fan', 'dividend_hunter', 'small_cap', 
  'international', 'consumer_staples', 'sector_rotator'
);

-- ============================================================================
-- 6. VERIFICATION QUERIES
-- ============================================================================

-- Verify the setup worked correctly
SELECT 'Schema setup completed successfully' as status;

-- Check achievement categories
SELECT achievement_category, COUNT(*) as count 
FROM public.user_achievements 
WHERE achievement_category IS NOT NULL
GROUP BY achievement_category
ORDER BY achievement_category;

-- Check metadata population
SELECT 
  COUNT(*) as total_achievements,
  COUNT(CASE WHEN achievement_title IS NOT NULL THEN 1 END) as with_title,
  COUNT(CASE WHEN achievement_category IS NOT NULL THEN 1 END) as with_category,
  COUNT(CASE WHEN icon_name IS NOT NULL THEN 1 END) as with_icon,
  COUNT(CASE WHEN color_hex IS NOT NULL THEN 1 END) as with_color
FROM public.user_achievements;

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

-- Your schema is now ready for the comprehensive database fixes!
-- Next step: Run comprehensive_database_fixes.sql to add the SQL functions