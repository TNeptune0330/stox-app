-- Fix Function Conflicts Script
-- Resolves "function name is not unique" errors by dropping all versions

-- ============================================================================
-- DROP ALL EXISTING FUNCTION VERSIONS
-- ============================================================================

-- Drop all possible versions of update_achievement_progress
DROP FUNCTION IF EXISTS update_achievement_progress(UUID, TEXT, INTEGER, INTEGER, JSONB) CASCADE;
DROP FUNCTION IF EXISTS update_achievement_progress(UUID, TEXT, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS update_achievement_progress CASCADE;

-- Drop all possible versions of unlock_achievement  
DROP FUNCTION IF EXISTS unlock_achievement(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS unlock_achievement(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS unlock_achievement CASCADE;

-- Drop other potentially conflicting functions
DROP FUNCTION IF EXISTS get_user_trade_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_user_achievement_progress(UUID) CASCADE;
DROP FUNCTION IF EXISTS sync_trade_achievements(UUID) CASCADE;
DROP FUNCTION IF EXISTS recalculate_user_trade_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS migrate_achievement_categories() CASCADE;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Check that all functions have been dropped
SELECT 
  routine_name, 
  specific_name,
  routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    'update_achievement_progress',
    'unlock_achievement', 
    'get_user_trade_count',
    'get_user_achievement_progress',
    'sync_trade_achievements',
    'recalculate_user_trade_count',
    'migrate_achievement_categories'
  )
ORDER BY routine_name;

-- If this query returns no rows, all conflicting functions have been successfully dropped
-- You can now run the comprehensive_database_fixes.sql script without conflicts