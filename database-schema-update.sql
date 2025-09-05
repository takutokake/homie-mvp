-- Add new columns to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sms_consent BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS school TEXT,
  ADD COLUMN IF NOT EXISTS school_area TEXT,
  ADD COLUMN IF NOT EXISTS interests TEXT[],
  ADD COLUMN IF NOT EXISTS hangout_types TEXT[],
  ADD COLUMN IF NOT EXISTS preferred_time_of_day TEXT[],
  ADD COLUMN IF NOT EXISTS preferred_days TEXT[],
  ADD COLUMN IF NOT EXISTS meeting_preference TEXT[],
  ADD COLUMN IF NOT EXISTS bio TEXT,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create ENUM type for price range if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'price_range') THEN
    CREATE TYPE price_range AS ENUM ('$', '$$', '$$$', '$$$$');
  END IF;
END $$;

-- Update existing price_range type if needed
ALTER TABLE users 
  DROP COLUMN IF EXISTS price_range;
ALTER TABLE users 
  ADD COLUMN price_range VARCHAR(4) CHECK (price_range IN ('$', '$$', '$$$', '$$$$'));

-- Add indices for new searchable columns
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school);
CREATE INDEX IF NOT EXISTS idx_users_profile_completed ON users(profile_completed);

-- Update invites table
ALTER TABLE invites
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS school_restriction TEXT;

DROP TRIGGER IF EXISTS invites_updated_at ON invites;
CREATE TRIGGER invites_updated_at
    BEFORE UPDATE ON invites
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
