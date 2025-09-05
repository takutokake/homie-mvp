-- Add missing columns with snake_case naming
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS sms_consent BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS price_range TEXT,
  ADD COLUMN IF NOT EXISTS preferred_time_of_day TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS preferred_days TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS meeting_preference TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Add indices for performance
CREATE INDEX IF NOT EXISTS idx_users_profile_completed ON users(profile_completed);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school);

-- Update RLS policies to use snake_case
DROP POLICY IF EXISTS users_read_public ON users;
CREATE POLICY users_read_public ON users
  FOR SELECT
  USING (
    profile_completed = true AND
    id != auth.uid()::uuid
  );
