-- Quick fix for function signature conflicts
-- Run this first if you get "cannot change return type" errors

-- Drop all existing function versions that might conflict
DROP FUNCTION IF EXISTS update_achievement_progress(UUID, TEXT, INTEGER, INTEGER, JSONB);
DROP FUNCTION IF EXISTS update_achievement_progress(UUID, TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS unlock_achievement(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS unlock_achievement(UUID, TEXT);

-- Now you can run the comprehensive_database_fixes.sql script without conflicts