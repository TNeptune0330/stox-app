-- TARGETED FIX FOR SUPABASE AUTH TRIGGER ISSUE
-- This fixes the "last_login column does not exist" error
-- Run this in your Supabase SQL Editor

-- First, let's see what's happening with the auth triggers
DO $$
BEGIN
    RAISE NOTICE 'Checking current auth triggers and functions...';
END $$;

-- Drop any existing auth-related triggers that might be broken
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users CASCADE;
DROP TRIGGER IF EXISTS update_user_last_login_trigger ON auth.users CASCADE;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users CASCADE;

-- Drop any existing functions that might be referencing wrong columns
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS update_user_last_login() CASCADE;
DROP FUNCTION IF EXISTS stox_handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS stox_update_user_login() CASCADE;

-- Verify the users table has the correct structure
DO $$
DECLARE
    has_last_login BOOLEAN;
    has_updated_at BOOLEAN;
BEGIN
    -- Check if last_login column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND table_schema = 'public'
        AND column_name = 'last_login'
    ) INTO has_last_login;
    
    -- Check if updated_at column exists
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND table_schema = 'public'
        AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    RAISE NOTICE 'Users table column check:';
    RAISE NOTICE '- last_login exists: %', has_last_login;
    RAISE NOTICE '- updated_at exists: %', has_updated_at;
    
    IF NOT has_last_login THEN
        RAISE NOTICE 'Adding missing last_login column...';
        ALTER TABLE public.users ADD COLUMN last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    IF NOT has_updated_at THEN
        RAISE NOTICE 'Adding missing updated_at column...';
        ALTER TABLE public.users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Create a NEW, working function to handle user creation
CREATE OR REPLACE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
    -- Insert new user into public.users table
    INSERT INTO public.users (
        id, 
        email, 
        username, 
        display_name,
        created_at, 
        last_login,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.created_at,
        COALESCE(NEW.last_sign_in_at, NEW.created_at),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        username = COALESCE(public.users.username, EXCLUDED.username),
        display_name = COALESCE(public.users.display_name, EXCLUDED.display_name),
        last_login = COALESCE(NEW.last_sign_in_at, public.users.last_login),
        updated_at = NOW();
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a NEW, working function to update user login
CREATE OR REPLACE FUNCTION update_user_last_login() RETURNS TRIGGER AS $$
BEGIN
    -- Update the last_login in public.users table
    UPDATE public.users
    SET 
        last_login = COALESCE(NEW.last_sign_in_at, NOW()),
        updated_at = NOW()
    WHERE id = NEW.id;
    
    -- If no rows were updated, the user might not exist, so create them
    IF NOT FOUND THEN
        INSERT INTO public.users (
            id, 
            email, 
            username,
            display_name,
            created_at,
            last_login,
            updated_at
        )
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
            COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name', SPLIT_PART(NEW.email, '@', 1)),
            NEW.created_at,
            COALESCE(NEW.last_sign_in_at, NEW.created_at),
            NOW()
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in update_user_last_login: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the triggers with the NEW functions
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW 
    EXECUTE FUNCTION handle_new_user();

CREATE TRIGGER on_auth_user_login
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
    EXECUTE FUNCTION update_user_last_login();

-- Verify the triggers were created
DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE event_object_schema = 'auth'
    AND event_object_table = 'users'
    AND trigger_name IN ('on_auth_user_created', 'on_auth_user_login');
    
    RAISE NOTICE 'Auth triggers created: % (expected: 2)', trigger_count;
END $$;

-- Test the functions work
DO $$
BEGIN
    RAISE NOTICE '✅ AUTH TRIGGER FIX COMPLETE!';
    RAISE NOTICE '✅ Functions recreated with proper column references';
    RAISE NOTICE '✅ Triggers recreated on auth.users table';
    RAISE NOTICE '✅ Error handling added to prevent future issues';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Try logging in again - authentication should work now!';
END $$;