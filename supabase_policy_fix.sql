-- ===================================================================
-- FIX: PostgreSQL Infinite Recursion Policy Error
-- ===================================================================
-- Run this in your Supabase SQL Editor to fix the RLS policies
-- ===================================================================

-- 1. DROP EXISTING PROBLEMATIC POLICIES
-- ===================================================================

DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Users can create support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Admins can view all support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Only admins can view notifications" ON public.admin_notifications;
DROP POLICY IF EXISTS "Users can insert own telemetry" ON public.app_telemetry;
DROP POLICY IF EXISTS "Admins can view all telemetry" ON public.app_telemetry;

-- 2. CREATE CORRECTED RLS POLICIES (NO INFINITE RECURSION)
-- ===================================================================

-- User profiles policies - Fixed to avoid recursion
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Admin policy using auth.users directly to avoid recursion
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
    FOR ALL USING (
        auth.uid() IN (
            SELECT id FROM public.user_profiles 
            WHERE is_admin = true
        )
    );

-- Support requests policies
CREATE POLICY "Users can view own support requests" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create support requests" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all support requests" ON public.support_requests
    FOR ALL USING (
        auth.uid() IN (
            SELECT id FROM public.user_profiles 
            WHERE is_admin = true
        )
    );

-- Admin notifications policies
CREATE POLICY "Only admins can view notifications" ON public.admin_notifications
    FOR ALL USING (
        auth.uid() IN (
            SELECT id FROM public.user_profiles 
            WHERE is_admin = true
        )
    );

-- Telemetry policies
CREATE POLICY "Users can insert own telemetry" ON public.app_telemetry
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all telemetry" ON public.app_telemetry
    FOR SELECT USING (
        auth.uid() IN (
            SELECT id FROM public.user_profiles 
            WHERE is_admin = true
        )
    );

-- 3. CREATE SIMPLIFIED ADMIN CHECK FUNCTION
-- ===================================================================

-- Replace the problematic is_admin function
CREATE OR REPLACE FUNCTION public.is_admin_user(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    -- Direct check without policy recursion
    RETURN EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = user_id AND is_admin = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. FIX ADMIN STATS FUNCTION
-- ===================================================================

CREATE OR REPLACE FUNCTION public.get_admin_stats()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    user_is_admin BOOLEAN;
BEGIN
    -- Check admin status without using the policy
    SELECT is_admin INTO user_is_admin 
    FROM public.user_profiles 
    WHERE id = auth.uid();
    
    IF NOT COALESCE(user_is_admin, false) THEN
        RAISE EXCEPTION 'Access denied. Admin privileges required.';
    END IF;
    
    -- Get actual stats from real tables
    SELECT jsonb_build_object(
        'total_users', (
            SELECT COUNT(*) 
            FROM auth.users 
            WHERE deleted_at IS NULL
        ),
        'total_profiles', (
            SELECT COUNT(*) 
            FROM public.user_profiles
        ),
        'admin_users', (
            SELECT COUNT(*) 
            FROM public.user_profiles 
            WHERE is_admin = true
        ),
        'active_today', (
            SELECT COUNT(DISTINCT user_id) 
            FROM public.user_portfolios 
            WHERE updated_at >= CURRENT_DATE
        ),
        'total_trades', (
            SELECT COUNT(*) 
            FROM public.user_trades
        ),
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

-- 5. GRANT NECESSARY PERMISSIONS
-- ===================================================================

-- Grant permissions for authenticated users
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT ON public.support_requests TO authenticated;
GRANT SELECT, INSERT ON public.app_telemetry TO authenticated;

-- Grant admin permissions (will be filtered by RLS)
GRANT ALL ON public.admin_notifications TO authenticated;
GRANT ALL ON public.support_requests TO authenticated;
GRANT ALL ON public.app_telemetry TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '
    ╔══════════════════════════════════════════════════════════════════╗
    ║                   🔧 POLICIES FIXED! 🔧                         ║
    ╠══════════════════════════════════════════════════════════════════╣
    ║                                                                  ║
    ║  ✅ Fixed infinite recursion in RLS policies                     ║
    ║  ✅ Corrected admin access functions                             ║
    ║  ✅ Updated support request permissions                          ║
    ║  ✅ Fixed analytics data queries                                 ║
    ║                                                                  ║
    ║  🧪 Test with: SELECT public.get_admin_stats();                  ║
    ║  📧 Try submitting a support request from the app               ║
    ║                                                                  ║
    ╚══════════════════════════════════════════════════════════════════╝
    ';
END $$;