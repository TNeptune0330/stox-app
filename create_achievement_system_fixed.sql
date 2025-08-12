-- Create Achievement System Tables and Functions
-- Run this in your Supabase SQL Editor

-- Create achievement category enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE achievement_category AS ENUM ('trading', 'profit', 'streak', 'special', 'milestone');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create achievement_progress table
CREATE TABLE IF NOT EXISTS achievement_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  current_progress INTEGER DEFAULT 0,
  target_progress INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  progress_data JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Create user_achievements table  
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  achievement_title TEXT NOT NULL,
  achievement_description TEXT NOT NULL,
  achievement_category achievement_category NOT NULL,
  icon_name TEXT,
  color_hex TEXT,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Enable RLS
ALTER TABLE achievement_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own achievement progress" ON achievement_progress;
DROP POLICY IF EXISTS "Users can update own achievement progress" ON achievement_progress;
DROP POLICY IF EXISTS "Users can view own achievements" ON user_achievements;
DROP POLICY IF EXISTS "Users can insert own achievements" ON user_achievements;

-- Create RLS policies
CREATE POLICY "Users can view own achievement progress" ON achievement_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own achievement progress" ON achievement_progress
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_id ON achievement_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_achievement_id ON achievement_progress(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at DESC);

-- Create update_achievement_progress function
CREATE OR REPLACE FUNCTION update_achievement_progress(
  user_id_param UUID,
  achievement_id_param TEXT,
  progress_param INTEGER,
  target_param INTEGER,
  progress_data_param JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
  current_progress INTEGER;
  was_completed BOOLEAN;
  is_newly_completed BOOLEAN := FALSE;
BEGIN
  -- Insert or update achievement progress
  INSERT INTO achievement_progress (user_id, achievement_id, current_progress, target_progress, progress_data)
  VALUES (user_id_param, achievement_id_param, progress_param, target_param, progress_data_param)
  ON CONFLICT (user_id, achievement_id) DO UPDATE SET
    current_progress = progress_param,
    target_progress = target_param,
    progress_data = progress_data_param,
    updated_at = NOW()
  RETURNING current_progress, is_completed INTO current_progress, was_completed;

  -- Check if achievement is newly completed
  IF progress_param >= target_param AND NOT was_completed THEN
    is_newly_completed := TRUE;
    
    -- Mark as completed
    UPDATE achievement_progress 
    SET is_completed = TRUE 
    WHERE user_id = user_id_param AND achievement_id = achievement_id_param;
  END IF;

  RETURN jsonb_build_object(
    'success', TRUE,
    'current_progress', current_progress,
    'is_completed', progress_param >= target_param,
    'is_newly_completed', is_newly_completed
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create unlock_achievement function
CREATE OR REPLACE FUNCTION unlock_achievement(
  user_id_param UUID,
  achievement_id_param TEXT,
  title_param TEXT,
  description_param TEXT,
  category_param achievement_category,
  icon_param TEXT,
  color_param TEXT
) RETURNS JSONB AS $$
DECLARE
  existing_achievement UUID;
BEGIN
  -- Check if achievement already exists
  SELECT id INTO existing_achievement
  FROM user_achievements 
  WHERE user_id = user_id_param AND achievement_id = achievement_id_param;

  IF existing_achievement IS NOT NULL THEN
    RETURN jsonb_build_object('success', TRUE, 'already_unlocked', TRUE);
  END IF;

  -- Insert new achievement
  INSERT INTO user_achievements (
    user_id, 
    achievement_id, 
    achievement_title, 
    achievement_description, 
    achievement_category, 
    icon_name, 
    color_hex
  )
  VALUES (
    user_id_param, 
    achievement_id_param, 
    title_param, 
    description_param, 
    category_param, 
    icon_param, 
    color_param
  );

  -- Mark progress as completed if it exists
  UPDATE achievement_progress 
  SET is_completed = TRUE 
  WHERE user_id = user_id_param AND achievement_id = achievement_id_param;

  RETURN jsonb_build_object('success', TRUE, 'newly_unlocked', TRUE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON achievement_progress TO authenticated;
GRANT ALL ON user_achievements TO authenticated;
GRANT EXECUTE ON FUNCTION update_achievement_progress TO authenticated;
GRANT EXECUTE ON FUNCTION unlock_achievement TO authenticated;