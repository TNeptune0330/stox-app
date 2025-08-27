-- Schema cleanup script - Remove unused tables and fix mismatched structures
-- Run this in your Supabase SQL editor

-- WARNING: This will DROP tables and data. Make sure you have backups!

-- 1. Drop the achievement_progress table as it's not used by the code
-- The code expects achievement progress to be stored in user_achievements table
DROP TABLE IF EXISTS public.achievement_progress CASCADE;

-- 2. Update user_achievements table to match what the code expects
-- Add missing columns that the code uses
ALTER TABLE public.user_achievements 
ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS target INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS progress_data JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Modify unlocked_at to be nullable (achievement might be in progress)
ALTER TABLE public.user_achievements 
ALTER COLUMN unlocked_at DROP DEFAULT,
ALTER COLUMN unlocked_at DROP NOT NULL;

-- Add unique constraint that the code expects
DO $$ BEGIN
    ALTER TABLE public.user_achievements 
    ADD CONSTRAINT user_achievements_user_achievement_unique 
    UNIQUE (user_id, achievement_id);
EXCEPTION WHEN duplicate_table THEN
    -- Constraint already exists, skip
END $$;

-- 3. Update the table comment
COMMENT ON TABLE public.user_achievements IS 'User achievement progress and unlocked achievements - single table for both progress tracking and unlocked status';

-- 4. Create indexes for performance (if they don't exist)
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON public.user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked ON public.user_achievements(user_id, unlocked_at) WHERE unlocked_at IS NOT NULL;

-- 5. Drop and recreate the update_achievement_progress function to match the new schema
DROP FUNCTION IF EXISTS public.update_achievement_progress(uuid,text,integer,integer,jsonb);

CREATE OR REPLACE FUNCTION public.update_achievement_progress(
    user_id_param UUID,
    achievement_id_param TEXT,
    progress_param INTEGER,
    target_param INTEGER,
    progress_data_param JSONB DEFAULT '{}'
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
BEGIN
    -- Insert or update achievement progress in user_achievements table
    INSERT INTO public.user_achievements (
        user_id, achievement_id, progress, target, progress_data, updated_at
    ) VALUES (
        user_id_param, achievement_id_param, progress_param, target_param, progress_data_param, NOW()
    )
    ON CONFLICT (user_id, achievement_id) DO UPDATE SET
        progress = EXCLUDED.progress,
        target = EXCLUDED.target,
        progress_data = EXCLUDED.progress_data,
        updated_at = NOW();

    -- Check if achievement should be unlocked
    IF progress_param >= target_param THEN
        UPDATE public.user_achievements
        SET unlocked_at = NOW()
        WHERE user_id = user_id_param 
        AND achievement_id = achievement_id_param 
        AND unlocked_at IS NULL;
        
        result := '{"success": true, "unlocked": true}'::jsonb;
    ELSE
        result := '{"success": true, "unlocked": false}'::jsonb;
    END IF;
    
    RETURN result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.update_achievement_progress TO authenticated;

-- 6. Enable RLS on user_achievements if not already enabled
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;

-- 7. Create or replace RLS policies for user_achievements
DROP POLICY IF EXISTS "Users can read own achievements" ON public.user_achievements;
DROP POLICY IF EXISTS "Users can manage own achievements" ON public.user_achievements;

CREATE POLICY "Users can read own achievements" ON public.user_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own achievements" ON public.user_achievements
    FOR ALL USING (auth.uid() = user_id);

-- 8. Grant permissions
GRANT ALL ON public.user_achievements TO authenticated;

COMMENT ON FUNCTION public.update_achievement_progress IS 'Update user achievement progress and auto-unlock when target reached - works with unified user_achievements table';

-- 9. If you want to remove market_prices table (UNCOMMENT ONLY IF YOU'RE SURE):
-- WARNING: This will break market data functionality!
-- DROP TABLE IF EXISTS public.market_prices CASCADE;

-- Instead, let's keep market_prices but add a comment explaining its necessity:
COMMENT ON TABLE public.market_prices IS 'Market price data - REQUIRED for portfolio P&L calculations, leaderboards, and trading functionality';

PRINT 'Schema cleanup completed successfully!';