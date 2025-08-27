-- Clean up unused database tables and add missing ones
-- Run this in your Supabase SQL editor

-- 1. Remove the unused 'achievements' table (code uses 'user_achievements' instead)
DROP TABLE IF EXISTS public.achievements CASCADE;

-- 2. Remove indexes for achievements table
DROP INDEX IF EXISTS idx_achievements_user_id;

-- 3. Create the user_achievements table that the code actually uses
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL,
    progress INTEGER DEFAULT 0,
    target INTEGER DEFAULT 1,
    progress_data JSONB DEFAULT '{}',
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, achievement_id)
);

-- 4. Create the user_settings table that the code uses
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, setting_key)
);

-- 5. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON public.user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_settings_key ON public.user_settings(setting_key);

-- 6. Enable Row Level Security
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies for user_achievements
CREATE POLICY "Users can read own achievements" ON public.user_achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own achievements" ON public.user_achievements
    FOR ALL USING (auth.uid() = user_id);

-- 8. RLS Policies for user_settings  
CREATE POLICY "Users can read own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own settings" ON public.user_settings
    FOR ALL USING (auth.uid() = user_id);

-- 9. Create function to update achievement progress
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
    -- Insert or update achievement progress
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

-- 10. Grant permissions on new tables
GRANT ALL ON public.user_achievements TO authenticated;
GRANT ALL ON public.user_settings TO authenticated;

COMMENT ON TABLE public.user_achievements IS 'User achievement progress and unlocked achievements';
COMMENT ON TABLE public.user_settings IS 'User application settings and preferences';
COMMENT ON FUNCTION public.update_achievement_progress IS 'Update user achievement progress and auto-unlock when target reached';