-- Remove Unused Columns Script
-- Removes all sector-related and unused columns from the users table

-- ============================================================================
-- 1. REMOVE SECTOR-RELATED COLUMNS (No longer needed after removing sector achievements)
-- ============================================================================

-- Remove sectors_traded column (was used for sector-based achievements)
ALTER TABLE public.users DROP COLUMN IF EXISTS sectors_traded;

-- Remove asset_types_traded column (was used for asset type tracking)
ALTER TABLE public.users DROP COLUMN IF EXISTS asset_types_traded;

-- ============================================================================
-- 2. REMOVE OTHER UNUSED TRACKING COLUMNS
-- ============================================================================

-- These columns may not be actively used in the app and can be removed if not needed:

-- Remove months_active if not used
ALTER TABLE public.users DROP COLUMN IF EXISTS months_active;

-- Remove total_app_opens if not used for achievements
ALTER TABLE public.users DROP COLUMN IF EXISTS total_app_opens;

-- Remove total_screen_time_minutes if not used for achievements
ALTER TABLE public.users DROP COLUMN IF EXISTS total_screen_time_minutes;

-- Remove max_single_day_gain if not used for achievements
ALTER TABLE public.users DROP COLUMN IF EXISTS max_single_day_gain;

-- Remove max_single_day_loss if not used for achievements
ALTER TABLE public.users DROP COLUMN IF EXISTS max_single_day_loss;

-- ============================================================================
-- 3. KEEP ESSENTIAL COLUMNS FOR ACHIEVEMENTS AND FUNCTIONALITY
-- ============================================================================

-- These columns are kept because they're used by the achievement system:
-- - total_trades (used for trading achievements)
-- - current_streak, max_streak (used for streak achievements)
-- - win_rate (used for performance tracking)
-- - days_traded (used for milestone achievements)
-- - total_profit_loss (used for profit achievements)
-- - cash_balance, initial_balance, total_deposited (core functionality)
-- - max_portfolio_value (used for milestone achievements)
-- - total_fees_paid (financial tracking)

-- These columns are kept for user settings and functionality:
-- - notifications_enabled, dark_mode_enabled, sound_effects_enabled (user preferences)
-- - daily_loss_limit, position_size_limit (risk management)
-- - last_active_date, created_at, last_login, updated_at (user tracking)

-- ============================================================================
-- 4. VERIFICATION
-- ============================================================================

-- Show remaining columns in users table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================

-- The users table now only contains columns that are actually used by the app
-- All sector-related tracking has been removed since we eliminated sector achievements