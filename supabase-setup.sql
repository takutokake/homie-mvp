-- Create tables for Homie MVP in Supabase
CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    google_id TEXT UNIQUE,
    
    -- Profile Information
    display_name TEXT NOT NULL,
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
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Invites table
CREATE TABLE invites (
    code TEXT PRIMARY KEY CHECK (LENGTH(code) = 6 AND code ~ '^[A-Z0-9]+$'),
    created_by TEXT NOT NULL,
    max_uses INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    school_restriction TEXT CHECK (school_restriction IN ('USC', 'UCLA', 'BOTH')),
    invite_type TEXT DEFAULT 'general' CHECK (invite_type IN ('general', 'premium', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table
CREATE TABLE sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    jwt_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Sample invite codes
INSERT INTO invites (code, created_by, max_uses, school_restriction, invite_type) VALUES
('USC001', 'admin@homie', 50, 'USC', 'general'),
('UCLA01', 'admin@homie', 50, 'UCLA', 'general'),
('HOMIE1', 'admin@homie', 10, 'BOTH', 'premium'),
('TEST01', 'admin@homie', 5, 'BOTH', 'general');

-- Auto-update trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
