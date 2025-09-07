-- Insert 100 P0 referral codes with less guessable 6-character patterns
INSERT INTO referral_codes (code, owner_type, max_uses, school_restriction) VALUES
-- Batch 1: Mixed alphanumeric with special pattern (20 codes)
('XK9R4M', 'P0', 5, 'BOTH'),
('QW7P2N', 'P0', 5, 'BOTH'),
('HJ5T8V', 'P0', 5, 'BOTH'),
('YL3B6C', 'P0', 5, 'BOTH'),
('ZM4F9D', 'P0', 5, 'BOTH'),
('VN8K2H', 'P0', 5, 'BOTH'),
('WP6G3Q', 'P0', 5, 'BOTH'),
('UR5J7X', 'P0', 5, 'BOTH'),
('ST9M4Y', 'P0', 5, 'BOTH'),
('KL7H2W', 'P0', 5, 'BOTH'),
('BN5C8R', 'P0', 5, 'BOTH'),
('FQ4T6P', 'P0', 5, 'BOTH'),
('DX3V9M', 'P0', 5, 'BOTH'),
('GZ8B4K', 'P0', 5, 'BOTH'),
('JY6L7H', 'P0', 5, 'BOTH'),
('MR2W5N', 'P0', 5, 'BOTH'),
('CT7F3Q', 'P0', 5, 'BOTH'),
('PK4D8X', 'P0', 5, 'BOTH'),
('LH9G6B', 'P0', 5, 'BOTH'),
('RV5M2C', 'P0', 5, 'BOTH'),

-- Batch 2: Alternating consonants and numbers (20 codes)
('K7N4P8', 'P0', 5, 'BOTH'),
('R2M6T9', 'P0', 5, 'BOTH'),
('L5B8H3', 'P0', 5, 'BOTH'),
('W9C4Q7', 'P0', 5, 'BOTH'),
('F3X6V2', 'P0', 5, 'BOTH'),
('J8D5G4', 'P0', 5, 'BOTH'),
('H2Y7K9', 'P0', 5, 'BOTH'),
('T6L3M5', 'P0', 5, 'BOTH'),
('B4W8R6', 'P0', 5, 'BOTH'),
('N7P2X4', 'P0', 5, 'BOTH'),
('Q5H9C3', 'P0', 5, 'BOTH'),
('V8F4B7', 'P0', 5, 'BOTH'),
('G3K6T2', 'P0', 5, 'BOTH'),
('M9R5L8', 'P0', 5, 'BOTH'),
('C2V7H4', 'P0', 5, 'BOTH'),
('X6B3N9', 'P0', 5, 'BOTH'),
('P4T8G5', 'P0', 5, 'BOTH'),
('D7M2Q6', 'P0', 5, 'BOTH'),
('Y5W9F3', 'P0', 5, 'BOTH'),
('Z8L4K7', 'P0', 5, 'BOTH'),

-- Batch 3: Reversed pattern with mixed case (20 codes)
('9K4RxM', 'P0', 5, 'BOTH'),
('7P2NwQ', 'P0', 5, 'BOTH'),
('5T8VhJ', 'P0', 5, 'BOTH'),
('3B6CyL', 'P0', 5, 'BOTH'),
('4F9DzM', 'P0', 5, 'BOTH'),
('8K2HvN', 'P0', 5, 'BOTH'),
('6G3QwP', 'P0', 5, 'BOTH'),
('5J7XuR', 'P0', 5, 'BOTH'),
('9M4YsT', 'P0', 5, 'BOTH'),
('7H2WkL', 'P0', 5, 'BOTH'),
('5C8RbN', 'P0', 5, 'BOTH'),
('4T6PfQ', 'P0', 5, 'BOTH'),
('3V9MdX', 'P0', 5, 'BOTH'),
('8B4KgZ', 'P0', 5, 'BOTH'),
('6L7HjY', 'P0', 5, 'BOTH'),
('2W5NmR', 'P0', 5, 'BOTH'),
('7F3QcT', 'P0', 5, 'BOTH'),
('4D8XpK', 'P0', 5, 'BOTH'),
('9G6BlH', 'P0', 5, 'BOTH'),
('5M2CrV', 'P0', 5, 'BOTH'),

-- Batch 4: Symmetric patterns (20 codes)
('KN4NK7', 'P0', 5, 'BOTH'),
('RM6MR2', 'P0', 5, 'BOTH'),
('LB8BL5', 'P0', 5, 'BOTH'),
('WC4CW9', 'P0', 5, 'BOTH'),
('FX6XF3', 'P0', 5, 'BOTH'),
('JD5DJ8', 'P0', 5, 'BOTH'),
('HY7YH2', 'P0', 5, 'BOTH'),
('TL3LT6', 'P0', 5, 'BOTH'),
('BW8WB4', 'P0', 5, 'BOTH'),
('NP2PN7', 'P0', 5, 'BOTH'),
('QH9HQ5', 'P0', 5, 'BOTH'),
('VF4FV8', 'P0', 5, 'BOTH'),
('GK6KG3', 'P0', 5, 'BOTH'),
('MR5RM9', 'P0', 5, 'BOTH'),
('CV7VC2', 'P0', 5, 'BOTH'),
('XB3BX6', 'P0', 5, 'BOTH'),
('PT8TP4', 'P0', 5, 'BOTH'),
('DM2MD7', 'P0', 5, 'BOTH'),
('YW9WY5', 'P0', 5, 'BOTH'),
('ZL4LZ8', 'P0', 5, 'BOTH'),

-- Batch 5: Complex mixed patterns (20 codes)
('K4N7P2', 'P0', 5, 'BOTH'),
('R8M3T6', 'P0', 5, 'BOTH'),
('L2B9H4', 'P0', 5, 'BOTH'),
('W6C5Q8', 'P0', 5, 'BOTH'),
('F9X2V7', 'P0', 5, 'BOTH'),
('J3D8G5', 'P0', 5, 'BOTH'),
('H7Y4K2', 'P0', 5, 'BOTH'),
('T2L6M9', 'P0', 5, 'BOTH'),
('B5W3R7', 'P0', 5, 'BOTH'),
('N8P7X3', 'P0', 5, 'BOTH'),
('Q4H2C8', 'P0', 5, 'BOTH'),
('V7F6B4', 'P0', 5, 'BOTH'),
('G2K9T5', 'P0', 5, 'BOTH'),
('M6R4L2', 'P0', 5, 'BOTH'),
('C9V3H7', 'P0', 5, 'BOTH'),
('X3B8N4', 'P0', 5, 'BOTH'),
('P7T2G6', 'P0', 5, 'BOTH'),
('D4M9Q3', 'P0', 5, 'BOTH'),
('Y8W5F7', 'P0', 5, 'BOTH'),
('Z2L7K4', 'P0', 5, 'BOTH');

-- Update P1 code generation function to create 6-character codes
CREATE OR REPLACE FUNCTION generate_p1_referral_code(user_id UUID, referred_by_code TEXT, referred_by_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN := TRUE;
    attempt_count INTEGER := 0;
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Removed similar looking characters I,O,0,1
    code_length INTEGER := 6;
BEGIN
    -- Generate unique code for P1 user
    WHILE code_exists AND attempt_count < 10 LOOP
        new_code := '';
        -- Generate random 6-character code
        FOR i IN 1..code_length LOOP
            new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
        END LOOP;
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM referral_codes WHERE code = new_code) INTO code_exists;
        attempt_count := attempt_count + 1;
    END LOOP;
    
    -- If we couldn't generate a unique code, use timestamp-based fallback
    IF code_exists THEN
        new_code := substr(encode(sha256(user_id::text || clock_timestamp()::text)::bytea, 'hex'), 1, 6);
    END IF;
    
    -- Insert the new P1 referral code
    INSERT INTO referral_codes (
        code, 
        owner_id, 
        owner_type, 
        referred_by_code, 
        referred_by_user_id, 
        max_uses
    ) VALUES (
        upper(new_code), 
        user_id, 
        'P1', 
        referred_by_code, 
        referred_by_user_id, 
        3
    );
    
    RETURN upper(new_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
