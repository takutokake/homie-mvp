-- Drop existing tables and start fresh
DROP TABLE IF EXISTS referral_codes CASCADE;
DROP TABLE IF EXISTS referral_usage CASCADE;
DROP TABLE IF EXISTS referral_chain CASCADE;

-- Create simple referral_codes table
CREATE TABLE referral_codes (
    code TEXT PRIMARY KEY,
    max_uses INTEGER NOT NULL DEFAULT 5,
    used_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert 50 P0 codes for initial users
INSERT INTO referral_codes (code) VALUES
('Q4H2C8'),
('XK9R4M'),
('K7N4P8'),
('R2M6T9'),
('L5B8H3'),
('W9C4Q7'),
('F3X6V2'),
('J8D5G4'),
('H2Y7K9'),
('T6L3M5'),
('B4W8R6'),
('N7P2X4'),
('Q5H9C3'),
('V8F4B7'),
('G3K6T2'),
('M9R5L8'),
('C2V7H4'),
('X6B3N9'),
('P4T8G5'),
('D7M2Q6'),
('Y5W9F3'),
('Z8L4K7'),
('QW7P2N'),
('HJ5T8V'),
('YL3B6C'),
('ZM4F9D'),
('VN8K2H'),
('WP6G3Q'),
('UR5J7X'),
('ST9M4Y'),
('KL7H2W'),
('BN5C8R'),
('FQ4T6P'),
('DX3V9M'),
('GZ8B4K'),
('JY6L7H'),
('MR2W5N'),
('CT7F3Q'),
('PK4D8X'),
('LH9G6B'),
('RV5M2C'),
('K4N7P2'),
('R8M3T6'),
('L2B9H4'),
('W6C5Q8'),
('F9X2V7'),
('J3D8G5'),
('H7Y4K2'),
('T2L6M9'),
('B5W3R7');

-- Grant anonymous access (no RLS needed)
GRANT SELECT ON referral_codes TO anon;
GRANT SELECT ON referral_codes TO authenticated;

-- Create user_referral_codes table for generated codes
CREATE TABLE IF NOT EXISTS user_referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referral_code TEXT UNIQUE NOT NULL,
    referred_by_code TEXT, -- Track which code they used to sign up
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Grant access to user codes
GRANT SELECT, INSERT ON user_referral_codes TO authenticated;

-- Function to generate unique referral code for new users
CREATE OR REPLACE FUNCTION generate_user_referral_code(p_user_id UUID, p_referred_by_code TEXT DEFAULT NULL)
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN := TRUE;
    attempt_count INTEGER := 0;
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
BEGIN
    -- Check if user already has a code
    SELECT referral_code INTO new_code
    FROM user_referral_codes
    WHERE user_id = p_user_id;
    
    IF new_code IS NOT NULL THEN
        RETURN new_code;
    END IF;
    
    -- Generate unique 6-character code
    WHILE code_exists AND attempt_count < 10 LOOP
        new_code := '';
        FOR i IN 1..6 LOOP
            new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
        END LOOP;
        
        -- Check if code exists in either table
        SELECT EXISTS(
            SELECT 1 FROM referral_codes WHERE code = new_code
            UNION
            SELECT 1 FROM user_referral_codes WHERE referral_code = new_code
        ) INTO code_exists;
        
        attempt_count := attempt_count + 1;
    END LOOP;
    
    -- Fallback if needed
    IF code_exists THEN
        new_code := substr(encode(sha256(p_user_id::text || clock_timestamp()::text)::bytea, 'hex'), 1, 6);
    END IF;
    
    -- Insert the new code with referral tracking
    INSERT INTO user_referral_codes (user_id, referral_code, referred_by_code)
    VALUES (p_user_id, upper(new_code), p_referred_by_code);
    
    RETURN upper(new_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's referral code
CREATE OR REPLACE FUNCTION get_user_referral_code(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_code TEXT;
BEGIN
    SELECT referral_code INTO user_code
    FROM user_referral_codes
    WHERE user_id = p_user_id;
    
    RETURN user_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test query
SELECT code, max_uses, used_count, is_active 
FROM referral_codes 
WHERE code = 'Q4H2C8';
