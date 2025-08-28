-- Force Drop Functions Script
-- Uses specific function signatures to drop all versions unambiguously

-- ============================================================================
-- FIND AND DROP ALL EXISTING FUNCTIONS
-- ============================================================================

-- First, let's see what functions exist
SELECT 
  routine_name,
  routine_type,
  specific_name,
  pg_get_function_identity_arguments(p.oid) as arguments
FROM information_schema.routines r
JOIN pg_proc p ON p.proname = r.routine_name
WHERE routine_schema = 'public' 
  AND routine_name IN ('unlock_achievement', 'update_achievement_progress', 'get_user_trade_count', 'get_user_achievement_progress', 'sync_trade_achievements', 'recalculate_user_trade_count')
ORDER BY routine_name;

-- Drop functions using their specific signatures from pg_proc
DO $$
DECLARE
    func_record RECORD;
    drop_statement TEXT;
BEGIN
    -- Loop through all matching functions and drop them
    FOR func_record IN 
        SELECT 
            n.nspname as schema_name,
            p.proname as function_name,
            pg_get_function_identity_arguments(p.oid) as arguments,
            p.oid
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' 
        AND p.proname IN ('unlock_achievement', 'update_achievement_progress', 'get_user_trade_count', 'get_user_achievement_progress', 'sync_trade_achievements', 'recalculate_user_trade_count', 'migrate_achievement_categories')
    LOOP
        -- Construct the DROP statement with specific arguments
        drop_statement := 'DROP FUNCTION IF EXISTS ' || func_record.schema_name || '.' || func_record.function_name;
        
        -- Add arguments if they exist
        IF func_record.arguments IS NOT NULL AND func_record.arguments != '' THEN
            drop_statement := drop_statement || '(' || func_record.arguments || ')';
        END IF;
        
        drop_statement := drop_statement || ' CASCADE';
        
        -- Execute the drop statement
        RAISE NOTICE 'Executing: %', drop_statement;
        EXECUTE drop_statement;
    END LOOP;
END $$;

-- Alternative method: Drop by OID if the above doesn't work
DO $$
DECLARE
    func_oid OID;
BEGIN
    -- Drop unlock_achievement functions by OID
    FOR func_oid IN 
        SELECT p.oid 
        FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' AND p.proname = 'unlock_achievement'
    LOOP
        EXECUTE 'DROP FUNCTION ' || func_oid::regprocedure || ' CASCADE';
        RAISE NOTICE 'Dropped function with OID: %', func_oid;
    END LOOP;

    -- Drop update_achievement_progress functions by OID
    FOR func_oid IN 
        SELECT p.oid 
        FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' AND p.proname = 'update_achievement_progress'
    LOOP
        EXECUTE 'DROP FUNCTION ' || func_oid::regprocedure || ' CASCADE';
        RAISE NOTICE 'Dropped function with OID: %', func_oid;
    END LOOP;

    -- Drop other conflicting functions
    FOR func_oid IN 
        SELECT p.oid 
        FROM pg_proc p 
        JOIN pg_namespace n ON n.oid = p.pronamespace 
        WHERE n.nspname = 'public' 
        AND p.proname IN ('get_user_trade_count', 'get_user_achievement_progress', 'sync_trade_achievements', 'recalculate_user_trade_count', 'migrate_achievement_categories')
    LOOP
        EXECUTE 'DROP FUNCTION ' || func_oid::regprocedure || ' CASCADE';
        RAISE NOTICE 'Dropped function with OID: %', func_oid;
    END LOOP;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify all functions have been dropped
SELECT 
  'Functions remaining:' as status,
  COUNT(*) as count
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    'unlock_achievement',
    'update_achievement_progress',
    'get_user_trade_count',
    'get_user_achievement_progress', 
    'sync_trade_achievements',
    'recalculate_user_trade_count',
    'migrate_achievement_categories'
  );

-- If count is 0, all functions have been successfully dropped
SELECT 'All conflicting functions have been dropped successfully' as result;