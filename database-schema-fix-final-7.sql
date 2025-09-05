-- Drop all existing policies first
DO $$ 
BEGIN
    -- Drop users policies if table exists
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'users') THEN
        DROP POLICY IF EXISTS "Users can view own profile" ON users;
        DROP POLICY IF EXISTS "Users can update own profile" ON users;
        DROP POLICY IF EXISTS "Users can insert own profile" ON users;
        DROP POLICY IF EXISTS "Users can view other completed profiles" ON users;
    END IF;

    -- Drop invites policies if table exists
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'invites') THEN
        DROP POLICY IF EXISTS "Users can read own invites" ON invites;
        DROP POLICY IF EXISTS "Users can create invites" ON invites;
        DROP POLICY IF EXISTS "Users can read school invites" ON invites;
        DROP POLICY IF EXISTS "invites_read_school" ON invites;
    END IF;
END $$;

-- Drop existing tables
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS invites CASCADE;

-- Create users table
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    username TEXT, -- Allow NULL initially, will be set during profile completion
    google_id TEXT UNIQUE,
    
    -- Profile Information
    display_name TEXT,
    phone_number TEXT,
    profile_picture_url TEXT,
    
    -- Location & School
    school TEXT CHECK (school IN ('USC', 'UCLA')),
    location_details TEXT,
    
    -- Preferences
    price_range TEXT CHECK (price_range IN ('$', '$$', '$$$', '$$$$')),
    meeting_preference TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',
    cuisine_preferences TEXT[] DEFAULT '{}',
    
    -- Profile Status
    profile_completed BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    sms_consent BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Create invites table
CREATE TABLE invites (
    code TEXT PRIMARY KEY,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    max_uses INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    school_restriction TEXT CHECK (school_restriction IN ('USC', 'UCLA', 'BOTH')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view other completed profiles" ON users;

-- Drop invites policies
DROP POLICY IF EXISTS "Users can read own invites" ON invites;
DROP POLICY IF EXISTS "Users can create invites" ON invites;
DROP POLICY IF EXISTS "Users can read school invites" ON invites;
DROP POLICY IF EXISTS "invites_read_school" ON invites;

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (id = auth.uid())
    WITH CHECK (
        NOT EXISTS (
            SELECT 1 FROM users
            WHERE users.username = NEW.username
            AND users.username IS NOT NULL
            AND users.id != NEW.id
        )
    );

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (
        id = auth.uid() AND
        NOT EXISTS (
            SELECT 1 FROM users
            WHERE users.username = NEW.username
            AND users.username IS NOT NULL
        )
    );

CREATE POLICY "Users can view other completed profiles" ON users
    FOR SELECT USING (
        profile_completed = true AND
        username IS NOT NULL AND
        id != auth.uid()
    );

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON users TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school);
CREATE INDEX IF NOT EXISTS idx_users_profile_completed ON users(profile_completed);

-- No need for additional foreign key constraint since it's already defined in table creation

-- Create policies for invites
CREATE POLICY "Users can read own invites" ON invites
    FOR SELECT USING (created_by = auth.uid());

CREATE POLICY "Users can create invites" ON invites
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can read school invites" ON invites
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()
            AND users.school = invites.school_restriction
            AND users.profile_completed = true
        )
    );

-- Grant permissions for invites
GRANT SELECT, INSERT ON invites TO authenticated;
