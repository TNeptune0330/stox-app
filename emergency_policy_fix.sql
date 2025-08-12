-- EMERGENCY FIX: Remove problematic RLS policies temporarily
-- Run this if you're getting infinite recursion errors

-- Temporarily disable RLS to allow support requests
ALTER TABLE public.support_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- Drop problematic policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Users can create support requests" ON public.support_requests;
DROP POLICY IF EXISTS "Admins can view all support requests" ON public.support_requests;

-- Create simple, safe policies
CREATE POLICY "allow_own_profile_select" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "allow_own_profile_update" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "allow_own_profile_insert" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "allow_support_insert" ON public.support_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "allow_support_select" ON public.support_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Re-enable RLS
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Grant basic permissions
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT ON public.support_requests TO authenticated;

SELECT 'Emergency fix applied - support requests should work now!' as status;