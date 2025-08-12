-- ===================================================================
-- Email Notification Trigger for Support Requests
-- ===================================================================
-- This creates a database trigger to automatically send email notifications
-- when new support requests are submitted
-- ===================================================================

-- 1. Create email notification function
CREATE OR REPLACE FUNCTION public.notify_support_request()
RETURNS TRIGGER AS $$
DECLARE
    email_subject TEXT;
    email_body TEXT;
    webhook_url TEXT := 'https://hooks.zapier.com/hooks/catch/18143405/2abc123/'; -- Replace with your webhook
BEGIN
    -- Create email subject
    email_subject := '[Stox App Support] ' || UPPER(NEW.request_type) || ': ' || NEW.subject;
    
    -- Create email body
    email_body := '🔔 New Stox App Support Request

📧 From: ' || NEW.email || '
👤 User: ' || COALESCE(NEW.full_name, 'N/A') || '
🏷️ Type: ' || UPPER(NEW.request_type) || '
📋 Subject: ' || NEW.subject || '
⚡ Priority: ' || UPPER(NEW.priority) || '

📝 Description:
' || NEW.description || '

🔧 Technical Details:
• App Version: ' || COALESCE(NEW.app_version, 'N/A') || '
• Device Info: ' || COALESCE(NEW.device_info, 'N/A') || '
• User ID: ' || NEW.user_id || '
• Request ID: ' || NEW.id || '
• Submitted: ' || NEW.created_at::text || '

---
Reply to: ' || NEW.email || '

Stox Trading Simulator Support System';

    -- Log the notification (this will appear in database logs)
    RAISE NOTICE 'EMAIL NOTIFICATION TO pradhancode@gmail.com:';
    RAISE NOTICE 'Subject: %', email_subject;
    RAISE NOTICE 'Body: %', email_body;
    
    -- Try to send via HTTP request (requires http extension)
    -- Uncomment if you have http extension enabled:
    /*
    PERFORM net.http_post(
        url := webhook_url,
        headers := '{"Content-Type": "application/json"}'::jsonb,
        body := jsonb_build_object(
            'to', 'pradhancode@gmail.com',
            'subject', email_subject,
            'message', email_body,
            'request_data', row_to_json(NEW)
        )
    );
    */
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Create trigger
DROP TRIGGER IF EXISTS support_request_email_trigger ON public.support_requests;

CREATE TRIGGER support_request_email_trigger
    AFTER INSERT ON public.support_requests
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_support_request();

-- 3. Test the setup
DO $$
BEGIN
    RAISE NOTICE '✅ Email notification trigger created successfully!';
    RAISE NOTICE 'ℹ️  Email notifications will appear in database logs';
    RAISE NOTICE 'ℹ️  Check Supabase logs dashboard for email content';
END $$;