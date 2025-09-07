-- Add referral chain tracking without modifying existing tables
CREATE TABLE IF NOT EXISTS referral_chain (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    referral_code TEXT NOT NULL,
    referred_by_code TEXT,
    referred_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    chain_level INTEGER NOT NULL, -- P0 = 0, P1 = 1, P2 = 2, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE referral_chain ENABLE ROW LEVEL SECURITY;

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_referral_chain_user ON referral_chain(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_chain_code ON referral_chain(referral_code);
CREATE INDEX IF NOT EXISTS idx_referral_chain_referred_by ON referral_chain(referred_by_code);
CREATE INDEX IF NOT EXISTS idx_referral_chain_level ON referral_chain(chain_level);

-- Policies for referral chain
CREATE POLICY "Users can view own referral chain" ON referral_chain
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can view referrals they made" ON referral_chain
    FOR SELECT USING (referred_by_user_id = auth.uid());

-- Grant permissions
GRANT SELECT ON referral_chain TO authenticated;

-- Function to generate unique referral code for any chain level
CREATE OR REPLACE FUNCTION generate_chain_referral_code(
    p_user_id UUID,
    p_referred_by_code TEXT,
    p_referred_by_user_id UUID
)
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    code_exists BOOLEAN := TRUE;
    attempt_count INTEGER := 0;
    chain_level INTEGER;
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Removed confusing I,O,0,1
    code_length INTEGER := 6;
BEGIN
    -- Determine chain level
    IF p_referred_by_code IS NULL THEN
        chain_level := 0; -- P0
    ELSE
        SELECT (chain_level + 1) INTO chain_level
        FROM referral_chain
        WHERE referral_code = p_referred_by_code;
        
        IF chain_level IS NULL THEN
            chain_level := 1; -- Default to P1 if can't determine
        END IF;
    END IF;

    -- Generate unique code
    WHILE code_exists AND attempt_count < 10 LOOP
        new_code := '';
        -- Generate random 6-character code
        FOR i IN 1..code_length LOOP
            new_code := new_code || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
        END LOOP;
        
        -- Check if code already exists
        SELECT EXISTS(
            SELECT 1 FROM referral_chain WHERE referral_code = new_code
        ) INTO code_exists;
        attempt_count := attempt_count + 1;
    END LOOP;
    
    -- Fallback to timestamp-based code if needed
    IF code_exists THEN
        new_code := substr(encode(sha256(p_user_id::text || clock_timestamp()::text)::bytea, 'hex'), 1, 6);
    END IF;
    
    -- Insert into referral chain
    INSERT INTO referral_chain (
        user_id,
        referral_code,
        referred_by_code,
        referred_by_user_id,
        chain_level
    ) VALUES (
        p_user_id,
        upper(new_code),
        p_referred_by_code,
        p_referred_by_user_id,
        chain_level
    );
    
    RETURN upper(new_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get full referral chain for a user
CREATE OR REPLACE FUNCTION get_referral_chain(p_user_id UUID)
RETURNS TABLE (
    level INTEGER,
    user_id UUID,
    referral_code TEXT,
    referred_by_code TEXT,
    referred_by_user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
WITH RECURSIVE chain AS (
    -- Base case: get the user's own referral info
    SELECT 
        rc.chain_level as level,
        rc.user_id,
        rc.referral_code,
        rc.referred_by_code,
        rc.referred_by_user_id,
        rc.created_at
    FROM referral_chain rc
    WHERE rc.user_id = p_user_id

    UNION ALL

    -- Recursive case: get all referrers up the chain
    SELECT 
        rc.chain_level,
        rc.user_id,
        rc.referral_code,
        rc.referred_by_code,
        rc.referred_by_user_id,
        rc.created_at
    FROM referral_chain rc
    INNER JOIN chain c ON rc.referral_code = c.referred_by_code
)
SELECT * FROM chain ORDER BY level;
$$ LANGUAGE SQL SECURITY DEFINER;
