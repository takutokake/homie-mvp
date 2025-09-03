-- Enhanced Users table with full profile information
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
    school TEXT CHECK (school IN ('USC', 'UCLA')) NOT NULL,
    location_details TEXT, -- specific campus area, dorm, etc.
    
    -- Preferences
    price_range TEXT CHECK (price_range IN ('$', '$$', '$$$', '$$$$')) NOT NULL,
    meeting_preference TEXT[] DEFAULT '{}', -- array: ['coffee', 'lunch', 'dinner', 'study', 'casual']
    interests TEXT[] DEFAULT '{}', -- array of interests
    cuisine_preferences TEXT[] DEFAULT '{}', -- array of cuisine types
    
    -- Profile Status
    profile_completed BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Enhanced Invites table (passcodes)
CREATE TABLE invites (
    code TEXT PRIMARY KEY CHECK (LENGTH(code) = 6 AND code ~ '^[A-Z0-9]+$'),
    created_by TEXT NOT NULL,
    max_uses INTEGER DEFAULT 1,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Invite restrictions
    school_restriction TEXT CHECK (school_restriction IN ('USC', 'UCLA', 'BOTH')),
    invite_type TEXT DEFAULT 'general' CHECK (invite_type IN ('general', 'premium', 'admin')),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sessions table (unchanged but included for completeness)
CREATE TABLE sessions (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id TEXT NOT NULL,
    jwt_id TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    revoked_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- User connections/matches table
CREATE TABLE user_connections (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user1_id TEXT NOT NULL,
    user2_id TEXT NOT NULL,
    connection_type TEXT DEFAULT 'match' CHECK (connection_type IN ('match', 'friend', 'blocked')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user1_id, user2_id)
);

-- Meetup events table
CREATE TABLE meetups (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    created_by TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT NOT NULL,
    price_range TEXT CHECK (price_range IN ('$', '$$', '$$$', '$$$$')),
    cuisine_type TEXT,
    max_participants INTEGER DEFAULT 4,
    current_participants INTEGER DEFAULT 1,
    scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'full', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

-- Meetup participants table
CREATE TABLE meetup_participants (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    meetup_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled', 'no_show')),
    FOREIGN KEY (meetup_id) REFERENCES meetups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(meetup_id, user_id)
);

-- Auto-update triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_users_school ON users(school);
CREATE INDEX idx_users_price_range ON users(price_range);
CREATE INDEX idx_users_profile_completed ON users(profile_completed);
CREATE INDEX idx_invites_school_restriction ON invites(school_restriction);
CREATE INDEX idx_meetups_scheduled_for ON meetups(scheduled_for);
CREATE INDEX idx_meetups_status ON meetups(status);

-- Sample invite codes for testing
INSERT INTO invites (code, created_by, max_uses, school_restriction, invite_type) VALUES
('USC001', 'admin@homie', 50, 'USC', 'general'),
('UCLA01', 'admin@homie', 50, 'UCLA', 'general'),
('HOMIE1', 'admin@homie', 10, 'BOTH', 'premium'),
('TEST01', 'admin@homie', 5, 'BOTH', 'general');

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetup_participants ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile and profiles of connected users
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id);

-- Meetups are visible to users of the same school
CREATE POLICY "Users can view meetups from same school" ON meetups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid()::text 
            AND users.school = (SELECT school FROM users WHERE users.id = meetups.created_by)
        )
    );
