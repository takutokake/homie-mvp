-- Drop old columns if they exist
ALTER TABLE users DROP COLUMN IF EXISTS "smsConsent";
ALTER TABLE users DROP COLUMN IF EXISTS "profileCompleted";

-- Add new columns with snake_case
ALTER TABLE users ADD COLUMN IF NOT EXISTS sms_consent BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view other completed profiles" ON users;

-- Create policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid()::text = id);

CREATE POLICY "Users can view other completed profiles" ON users
    FOR SELECT USING (
        profile_completed = true AND
        id != auth.uid()::text
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
