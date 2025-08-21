-- QUICK FIX: Add missing columns to existing users table
-- This will fix the immediate authentication error without full reset
-- Run this in your Supabase SQL Editor

-- Check if the column exists before adding it
DO $$
BEGIN
    -- Add last_login column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name='users' 
        AND column_name='last_login'
    ) THEN
        ALTER TABLE users ADD COLUMN last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added last_login column to users table';
    ELSE
        RAISE NOTICE 'last_login column already exists';
    END IF;

    -- Add other essential columns if they don't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name='users' 
        AND column_name='updated_at'
    ) THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to users table';
    END IF;

    -- Add cash_balance if missing
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name='users' 
        AND column_name='cash_balance'
    ) THEN
        ALTER TABLE users ADD COLUMN cash_balance NUMERIC DEFAULT 10000.00 CHECK (cash_balance >= 0);
        RAISE NOTICE 'Added cash_balance column to users table';
    END IF;

    -- Add total_trades if missing
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name='users' 
        AND column_name='total_trades'
    ) THEN
        ALTER TABLE users ADD COLUMN total_trades INTEGER DEFAULT 0;
        RAISE NOTICE 'Added total_trades column to users table';
    END IF;
END $$;

-- Update existing users to have proper default values
UPDATE users 
SET 
    last_login = COALESCE(last_login, NOW()),
    updated_at = COALESCE(updated_at, NOW())
WHERE last_login IS NULL OR updated_at IS NULL;

-- Create or replace the login update function
CREATE OR REPLACE FUNCTION update_user_last_login() RETURNS TRIGGER AS $$
BEGIN
  -- Update users table with last login info
  UPDATE users
  SET 
    last_login = COALESCE(NEW.last_sign_in_at, NOW()),
    updated_at = NOW()
  WHERE id = NEW.id;
  
  -- If user doesn't exist in users table, create them
  IF NOT FOUND THEN
    INSERT INTO users (
      id, email, username, display_name, 
      created_at, last_login, updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data ->> 'name', NEW.email),
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', NEW.email),
      NEW.created_at,
      COALESCE(NEW.last_sign_in_at, NEW.created_at),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
      last_login = COALESCE(NEW.last_sign_in_at, NOW()),
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION update_user_last_login();

-- Also create trigger for new user creation
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (
    id, email, username, display_name, 
    created_at, last_login, updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'name', NEW.email),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', NEW.email),
    NEW.created_at,
    COALESCE(NEW.last_sign_in_at, NEW.created_at),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Database columns fixed! Authentication should work now.';
  RAISE NOTICE 'For a complete reset, use safe_database_reset.sql instead.';
END $$;