-- Fix Supabase database schema issues for perfect sync
-- Run this in your Supabase SQL editor

-- 1. Create missing market_prices table
CREATE TABLE IF NOT EXISTS public.market_prices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    symbol TEXT NOT NULL UNIQUE,
    price NUMERIC NOT NULL,
    sector TEXT,
    type TEXT DEFAULT 'stock',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on market_prices
ALTER TABLE public.market_prices ENABLE ROW LEVEL SECURITY;

-- Allow all users to read market prices
CREATE POLICY "Anyone can read market prices" ON public.market_prices
    FOR SELECT USING (true);

-- Allow authenticated users to insert/update market prices
CREATE POLICY "Authenticated users can manage market prices" ON public.market_prices
    FOR ALL USING (auth.role() = 'authenticated');

-- 2. Drop duplicate stox_execute_trade functions to prevent conflicts
DROP FUNCTION IF EXISTS public.stox_execute_trade(uuid, text, public.trade_type, integer, numeric, numeric);
DROP FUNCTION IF EXISTS public.stox_execute_trade(uuid, text, text, integer, numeric, numeric);

-- 3. Create the correct stox_execute_trade function
CREATE OR REPLACE FUNCTION public.stox_execute_trade(
    user_id_param UUID,
    symbol_param TEXT,
    type_param TEXT,
    quantity_param INTEGER,
    price_param NUMERIC,
    total_amount_param NUMERIC
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_cash NUMERIC;
    current_shares INTEGER;
    new_cash NUMERIC;
    new_quantity INTEGER;
    new_avg_price NUMERIC;
    existing_position RECORD;
BEGIN
    -- Get current user cash balance
    SELECT cash_balance INTO current_cash
    FROM public.users 
    WHERE id = user_id_param;
    
    IF current_cash IS NULL THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Validate trade
    IF type_param = 'buy' THEN
        IF current_cash < total_amount_param THEN
            RAISE EXCEPTION 'Insufficient funds';
        END IF;
        new_cash := current_cash - total_amount_param;
    ELSIF type_param = 'sell' THEN
        -- Check if user has enough shares
        SELECT quantity INTO current_shares
        FROM public.portfolio 
        WHERE user_id = user_id_param AND symbol = symbol_param;
        
        current_shares := COALESCE(current_shares, 0);
        
        IF current_shares < quantity_param THEN
            RAISE EXCEPTION 'Insufficient shares';
        END IF;
        new_cash := current_cash + total_amount_param;
    ELSE
        RAISE EXCEPTION 'Invalid trade type';
    END IF;
    
    -- Update cash balance
    UPDATE public.users 
    SET cash_balance = new_cash, updated_at = NOW()
    WHERE id = user_id_param;
    
    -- Insert transaction record
    INSERT INTO public.transactions (
        user_id, symbol, type, quantity, price, total_value, timestamp
    ) VALUES (
        user_id_param, symbol_param, type_param, quantity_param, 
        price_param, total_amount_param, NOW()
    );
    
    -- Update portfolio
    SELECT * INTO existing_position
    FROM public.portfolio 
    WHERE user_id = user_id_param AND symbol = symbol_param;
    
    IF existing_position IS NULL THEN
        -- New position
        IF type_param = 'buy' THEN
            INSERT INTO public.portfolio (
                user_id, symbol, quantity, avg_price, created_at, updated_at
            ) VALUES (
                user_id_param, symbol_param, quantity_param, price_param, NOW(), NOW()
            );
        END IF;
    ELSE
        -- Update existing position
        IF type_param = 'buy' THEN
            new_quantity := existing_position.quantity + quantity_param;
            new_avg_price := ((existing_position.quantity * existing_position.avg_price) + 
                             (quantity_param * price_param)) / new_quantity;
        ELSE -- sell
            new_quantity := existing_position.quantity - quantity_param;
            new_avg_price := existing_position.avg_price; -- Keep same avg price
        END IF;
        
        IF new_quantity > 0 THEN
            UPDATE public.portfolio 
            SET quantity = new_quantity, 
                avg_price = new_avg_price,
                updated_at = NOW()
            WHERE user_id = user_id_param AND symbol = symbol_param;
        ELSE
            DELETE FROM public.portfolio 
            WHERE user_id = user_id_param AND symbol = symbol_param;
        END IF;
    END IF;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.stox_execute_trade TO authenticated;

-- 4. Insert some sample market data to prevent errors
INSERT INTO public.market_prices (symbol, price, sector, type) VALUES
    ('AAPL', 228.00, 'Technology', 'stock'),
    ('NVDA', 180.00, 'Technology', 'stock'),
    ('SOXL', 27.00, 'Technology', 'etf'),
    ('CRSP', 54.00, 'Healthcare', 'stock')
ON CONFLICT (symbol) DO UPDATE SET 
    price = EXCLUDED.price,
    updated_at = NOW();

-- 5. Create a function to sync local trades to Supabase
CREATE OR REPLACE FUNCTION public.sync_pending_trade(
    user_id_param UUID,
    symbol_param TEXT,
    type_param TEXT,
    quantity_param INTEGER,
    price_param NUMERIC,
    total_amount_param NUMERIC,
    timestamp_param TIMESTAMP WITH TIME ZONE
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if transaction already exists
    IF EXISTS (
        SELECT 1 FROM public.transactions 
        WHERE user_id = user_id_param 
        AND symbol = symbol_param 
        AND type = type_param 
        AND quantity = quantity_param 
        AND price = price_param 
        AND timestamp = timestamp_param
    ) THEN
        RETURN TRUE; -- Already synced
    END IF;
    
    -- Execute the trade
    RETURN public.stox_execute_trade(
        user_id_param, symbol_param, type_param, 
        quantity_param, price_param, total_amount_param
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.sync_pending_trade TO authenticated;

-- 6. Update users table to ensure proper cash balance handling
ALTER TABLE public.users 
ALTER COLUMN cash_balance SET DEFAULT 10000.0,
ALTER COLUMN cash_balance SET NOT NULL;

-- Update any null cash balances
UPDATE public.users SET cash_balance = 10000.0 WHERE cash_balance IS NULL;

COMMENT ON FUNCTION public.stox_execute_trade IS 'Execute a stock trade with full validation and portfolio updates';
COMMENT ON FUNCTION public.sync_pending_trade IS 'Sync a pending local trade to Supabase';
COMMENT ON TABLE public.market_prices IS 'Current market prices for stocks and ETFs';