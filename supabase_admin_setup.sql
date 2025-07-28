-- ===================================================================
-- STOX APP - ADMIN SYSTEM & THEME SETUP
-- ===================================================================
-- This script adds admin functionality and theme saving to your Stox app
-- Run this in your Supabase SQL Editor
-- ===================================================================

-- 1. ADD NEW COLUMNS TO USER PROFILES TABLE
-- ===================================================================

-- Check if user_profiles table exists, create if not
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add theme saving column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS color_theme TEXT DEFAULT 'default';

-- Add admin status column
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- Add comment to clarify purpose
COMMENT ON COLUMN public.user_profiles.color_theme IS 'Stores user selected theme (default, blue, green, purple, orange, red, custom)';
COMMENT ON COLUMN public.user_profiles.is_admin IS 'Admin status - enables analytics, telemetry, and admin functions';

-- ===================================================================
-- 2. SET ADMIN STATUS FOR YOUR EMAIL
-- ===================================================================

-- Set pradhancode@gmail.com as admin
UPDATE public.user_profiles 
SET is_admin = TRUE 
WHERE email = 'pradhancode@gmail.com';

-- If profile doesn't exist yet, insert it when user signs up (handled by trigger below)

-- ===================================================================
-- 3. CREATE SUPPORT REQUESTS TABLE
-- ===================================================================

CREATE TABLE IF NOT EXISTS public.support_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT,
    request_type TEXT NOT NULL CHECK (request_type IN ('bug', 'feature', 'support', 'feedback')),
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    app_version TEXT,
    device_info TEXT,
    screenshot_url TEXT,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    admin_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_support_requests_user_id ON public.support_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_support_requests_status ON public.support_requests(status);
CREATE INDEX IF NOT EXISTS idx_support_requests_type ON public.support_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_support_requests_created_at ON public.support_requests(created_at DESC);

-- Add comments
COMMENT ON TABLE public.support_requests IS 'User bug reports, feature requests, and support tickets';
COMMENT ON COLUMN public.support_requests.request_type IS 'Type of request: bug, feature, support, feedback';
COMMENT ON COLUMN public.support_requests.priority IS 'Priority level: low, medium, high, critical';
COMMENT ON COLUMN public.support_requests.status IS 'Request status: open, in_progress, resolved, closed';

-- ===================================================================
-- 4. CREATE ADMIN NOTIFICATIONS TABLE
-- ===================================================================

CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'warning', 'error', 'success')),
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at ON public.admin_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_is_read ON public.admin_notifications(is_read);

-- ===================================================================
-- 5. CREATE APP TELEMETRY TABLE
-- ===================================================================

CREATE TABLE IF NOT EXISTS public.app_telemetry (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    event_name TEXT NOT NULL,
    event_data JSONB,
    session_id TEXT,
    app_version TEXT,
    platform TEXT,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_app_telemetry_user_id ON public.app_telemetry(user_id);
CREATE INDEX IF NOT EXISTS idx_app_telemetry_event_name ON public.app_telemetry(event_name);
CREATE INDEX IF NOT EXISTS idx_app_telemetry_created_at ON public.app_telemetry(created_at DESC);

-- Add partitioning by date for better performance (optional)
-- This creates monthly partitions for the telemetry table
CREATE TABLE IF NOT EXISTS public.app_telemetry_template (LIKE public.app_telemetry INCLUDING ALL);

-- ===================================================================
-- 6. CREATE TRIGGERS AND FUNCTIONS
-- ===================================================================

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.raw_user_meta_data->>'avatar_url'
    );
    
    -- Set admin status if email is pradhancode@gmail.com
    IF NEW.email = 'pradhancode@gmail.com' THEN
        UPDATE public.user_profiles 
        SET is_admin = TRUE 
        WHERE id = NEW.id;
        
        -- Create admin notification
        INSERT INTO public.admin_notifications (title, message, type, data)
        VALUES (
            'Admin User Signed Up',
            'Admin user pradhancode@gmail.com has signed up',
            'success',
            jsonb_build_object('user_id', NEW.id, 'email', NEW.email)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
DROP TRIGGER IF EXISTS handle_updated_at ON public.user_profiles;
CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS handle_updated_at ON public.support_requests;
CREATE TRIGGER handle_updated_at
    BEFORE UPDATE ON public.support_requests
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ===================================================================
-- 7. EMAIL NOTIFICATION FUNCTION (Edge Function)
-- ===================================================================

-- Function to send email notifications for support requests
CREATE OR REPLACE FUNCTION public.notify_admin_support_request()
RETURNS TRIGGER AS $$
BEGIN
    -- Create admin notification
    INSERT INTO public.admin_notifications (title, message, type, data)
    VALUES (
        'New Support Request',
        format('New %s request: %s', NEW.request_type, NEW.subject),
        CASE 
            WHEN NEW.request_type = 'bug' THEN 'error'
            WHEN NEW.priority = 'critical' THEN 'warning'
            ELSE 'info'
        END,
        jsonb_build_object(
            'request_id', NEW.id,
            'user_email', NEW.email,
            'type', NEW.request_type,
            'priority', NEW.priority
        )
    );
    
    -- TODO: Add email sending via Edge Function or external service
    -- This would typically call a Supabase Edge Function to send email to pradhancode@gmail.com
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for support request notifications
DROP TRIGGER IF EXISTS notify_admin_support_request ON public.support_requests;
CREATE TRIGGER notify_admin_support_request
    AFTER INSERT ON public.support_requests
    FOR EACH ROW EXECUTE FUNCTION public.notify_admin_support_request();

-- ===================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ===================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_telemetry ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.user_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- Support requests policies
CREATE POLICY "Users can view own support requests" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create support requests" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all support requests" ON public.support_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- Admin notifications policies
CREATE POLICY "Only admins can view notifications" ON public.admin_notifications
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- Telemetry policies
CREATE POLICY "Users can insert own telemetry" ON public.app_telemetry
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all telemetry" ON public.app_telemetry
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND is_admin = TRUE
        )
    );

-- ===================================================================
-- 9. ADMIN HELPER FUNCTIONS
-- ===================================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = user_id AND is_admin = TRUE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get admin stats
CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    -- Only allow admins to call this function
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Access denied. Admin privileges required.';
    END IF;
    
    SELECT jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM auth.users),
        'total_profiles', (SELECT COUNT(*) FROM public.user_profiles),
        'admin_users', (SELECT COUNT(*) FROM public.user_profiles WHERE is_admin = TRUE),
        'active_today', (
            SELECT COUNT(DISTINCT user_id) 
            FROM public.user_portfolios 
            WHERE updated_at >= CURRENT_DATE
        ),
        'total_trades', (SELECT COUNT(*) FROM public.user_trades),
        'support_requests', (
            SELECT jsonb_build_object(
                'total', COUNT(*),
                'open', COUNT(*) FILTER (WHERE status = 'open'),
                'in_progress', COUNT(*) FILTER (WHERE status = 'in_progress')
            )
            FROM public.support_requests
        ),
        'last_updated', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================================================
-- 10. INSERT SAMPLE ADMIN NOTIFICATION
-- ===================================================================

INSERT INTO public.admin_notifications (title, message, type, data)
VALUES (
    'Admin System Setup Complete',
    'Admin system has been successfully configured. You can now access analytics, telemetry, and support requests.',
    'success',
    jsonb_build_object(
        'setup_date', NOW(),
        'admin_email', 'pradhancode@gmail.com',
        'features', jsonb_build_array('analytics', 'telemetry', 'support_requests', 'user_management')
    )
);

-- ===================================================================
-- SETUP COMPLETE MESSAGE
-- ===================================================================

DO $$
BEGIN
    RAISE NOTICE '
    ╔══════════════════════════════════════════════════════════════════╗
    ║                    🎉 SETUP COMPLETE! 🎉                        ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  ✅ Added color_theme column to user_profiles                    ║
    ║  ✅ Added is_admin column to user_profiles                       ║
    ║  ✅ Set pradhancode@gmail.com as admin                           ║
    ║  ✅ Created support_requests table                               ║
    ║  ✅ Created admin_notifications table                            ║
    ║  ✅ Created app_telemetry table                                  ║
    ║  ✅ Set up RLS policies and triggers                             ║
    ║  ✅ Created admin helper functions                               ║
    ║                                                                  ║
    ║  📧 Support emails will be sent to: pradhancode@gmail.com        ║
    ║  👤 Admin user: pradhancode@gmail.com                            ║
    ║                                                                  ║
    ║  Next Steps:                                                     ║
    ║  1. Update your Flutter app to use is_admin column              ║
    ║  2. Implement support request form                               ║
    ║  3. Set up email notifications (Edge Function)                   ║
    ║  4. Test admin functionality                                     ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
    ';
END $$;

-- ===================================================================
-- VERIFICATION QUERIES (Run these to test the setup)
-- ===================================================================

-- Check if columns were added
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'user_profiles' 
-- AND column_name IN ('color_theme', 'is_admin');

-- Check admin status
-- SELECT id, email, is_admin, color_theme FROM public.user_profiles WHERE email = 'pradhancode@gmail.com';

-- Test admin stats function (only works if you're admin)
-- SELECT public.get_admin_stats();

-- View admin notifications
-- SELECT * FROM public.admin_notifications ORDER BY created_at DESC;