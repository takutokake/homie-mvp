-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own referral codes" ON referral_codes;
DROP POLICY IF EXISTS "Users can view referral codes they used" ON referral_codes;
DROP POLICY IF EXISTS "Public can view active P0 codes for verification" ON referral_codes;
DROP POLICY IF EXISTS "Public can verify active referral codes" ON referral_codes;
DROP POLICY IF EXISTS "Users can view own referral usage" ON referral_usage;
DROP POLICY IF EXISTS "Code owners can view usage of their codes" ON referral_usage;

-- Create referral_codes table (main table for P0 and P1 codes)
CREATE TABLE IF NOT EXISTS referral_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    owner_type TEXT NOT NULL CHECK (owner_type IN ('P0', 'P1')),
    referred_by_code TEXT,
    referred_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    max_uses INTEGER NOT NULL DEFAULT 5,
    used_count INTEGER NOT NULL DEFAULT 0,
    school_restriction TEXT CHECK (school_restriction IN ('BOTH', 'USC', 'UCLA')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create referral_usage table (tracks each use of a referral code)
CREATE TABLE IF NOT EXISTS referral_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_code_id UUID REFERENCES referral_codes(id) ON DELETE CASCADE,
    referral_code TEXT NOT NULL,
    used_by_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    used_by_email TEXT NOT NULL,
    user_school TEXT,
    profile_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_usage ENABLE ROW LEVEL SECURITY;

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_referral_codes_code ON referral_codes(code);
CREATE INDEX IF NOT EXISTS idx_referral_codes_owner ON referral_codes(owner_id);
CREATE INDEX IF NOT EXISTS idx_referral_codes_referred_by ON referral_codes(referred_by_code);
CREATE INDEX IF NOT EXISTS idx_referral_codes_active ON referral_codes(is_active);

CREATE INDEX IF NOT EXISTS idx_referral_usage_code ON referral_usage(referral_code);
CREATE INDEX IF NOT EXISTS idx_referral_usage_user ON referral_usage(used_by_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_usage_code_id ON referral_usage(referral_code_id);

-- Policies for referral_codes
CREATE POLICY "Users can view own referral codes" ON referral_codes
    FOR SELECT USING (owner_id = auth.uid());

CREATE POLICY "Users can view referral codes they used" ON referral_codes
    FOR SELECT USING (code IN (
        SELECT referred_by_code FROM referral_codes WHERE owner_id = auth.uid()
    ));

-- Allow anonymous users to verify active referral codes
CREATE POLICY "Public can verify active referral codes" ON referral_codes
    FOR SELECT USING (is_active = true);

-- Policies for referral_usage
CREATE POLICY "Users can view own referral usage" ON referral_usage
    FOR SELECT USING (used_by_user_id = auth.uid());

CREATE POLICY "Code owners can view usage of their codes" ON referral_usage
    FOR SELECT USING (referral_code_id IN (
        SELECT id FROM referral_codes WHERE owner_id = auth.uid()
    ));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON referral_codes TO authenticated;
GRANT SELECT, INSERT ON referral_usage TO authenticated;

-- Function to track referral usage
CREATE OR REPLACE FUNCTION track_referral_usage(
    code TEXT, 
    user_id UUID, 
    user_email TEXT, 
    user_school TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    referral_record RECORD;
    usage_count INTEGER;
BEGIN
    -- Get referral code details
    SELECT * INTO referral_record 
    FROM referral_codes 
    WHERE referral_codes.code = track_referral_usage.code 
    AND is_active = true 
    AND (expires_at IS NULL OR expires_at > NOW());
    
    -- Check if code exists and is valid
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check usage limits
    IF referral_record.used_count >= referral_record.max_uses THEN
        RETURN FALSE;
    END IF;
    
    -- Check if user already used this code
    IF EXISTS(SELECT 1 FROM referral_usage WHERE referral_code = track_referral_usage.code AND used_by_user_id = user_id) THEN
        RETURN FALSE;
    END IF;
    
    -- Record the usage
    INSERT INTO referral_usage (
        referral_code_id,
        referral_code,
        used_by_user_id,
        used_by_email,
        user_school
    ) VALUES (
        referral_record.id,
        track_referral_usage.code,
        user_id,
        user_email,
        user_school
    );
    
    -- Update usage count
    UPDATE referral_codes 
    SET used_count = used_count + 1 
    WHERE id = referral_record.id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
