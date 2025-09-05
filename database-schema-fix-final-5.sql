-- First drop all existing RLS policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS users_read_own ON users;
  DROP POLICY IF EXISTS users_update_own ON users;
  DROP POLICY IF EXISTS users_read_public ON users;
  DROP POLICY IF EXISTS users_insert_self ON users;
  DROP POLICY IF EXISTS admin_all ON users;
  DROP POLICY IF EXISTS invites_read_own ON invites;
  DROP POLICY IF EXISTS invites_insert_own ON invites;
  DROP POLICY IF EXISTS invites_read_school ON invites;
  DROP POLICY IF EXISTS invites_admin_all ON invites;
END $$;

-- Rename all camelCase columns to snake_case
DO $$ 
BEGIN
  -- Users table
  ALTER TABLE users RENAME COLUMN "displayName" TO display_name;
  ALTER TABLE users RENAME COLUMN "phoneNumber" TO phone_number;
  ALTER TABLE users RENAME COLUMN "smsConsent" TO sms_consent;
  ALTER TABLE users RENAME COLUMN "priceRange" TO price_range;
  ALTER TABLE users RENAME COLUMN "preferredTimeOfDay" TO preferred_time_of_day;
  ALTER TABLE users RENAME COLUMN "preferredDays" TO preferred_days;
  ALTER TABLE users RENAME COLUMN "meetingPreference" TO meeting_preference;
  ALTER TABLE users RENAME COLUMN "profileCompleted" TO profile_completed;
  ALTER TABLE users RENAME COLUMN "isActive" TO is_active;
  ALTER TABLE users RENAME COLUMN "createdAt" TO created_at;
  ALTER TABLE users RENAME COLUMN "updatedAt" TO updated_at;
  ALTER TABLE users RENAME COLUMN "schoolArea" TO school_area;

  -- Invites table
  ALTER TABLE invites RENAME COLUMN "createdBy" TO created_by;
  ALTER TABLE invites RENAME COLUMN "maxUses" TO max_uses;
  ALTER TABLE invites RENAME COLUMN "usedCount" TO used_count;
  ALTER TABLE invites RENAME COLUMN "expiresAt" TO expires_at;
  ALTER TABLE invites RENAME COLUMN "isActive" TO is_active;
  ALTER TABLE invites RENAME COLUMN "schoolRestriction" TO school_restriction;
  ALTER TABLE invites RENAME COLUMN "inviteType" TO invite_type;
  ALTER TABLE invites RENAME COLUMN "createdAt" TO created_at;
EXCEPTION
  WHEN undefined_column THEN null;
END $$;

-- Add any missing columns
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS sms_consent BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS display_name TEXT,
  ADD COLUMN IF NOT EXISTS price_range TEXT CHECK (price_range IN ('$', '$$', '$$$', '$$$$')),
  ADD COLUMN IF NOT EXISTS preferred_time_of_day TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS preferred_days TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS meeting_preference TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  ADD COLUMN IF NOT EXISTS school_area TEXT;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;

-- Create RLS policies with snake_case column names
CREATE POLICY users_read_own ON users
  FOR SELECT
  USING (auth.uid()::uuid = id);

CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid()::uuid = id);

CREATE POLICY users_read_public ON users
  FOR SELECT
  USING (
    profile_completed = true AND
    id != auth.uid()::uuid
  );

CREATE POLICY users_insert_self ON users
  FOR INSERT
  WITH CHECK (auth.uid()::uuid = id);

CREATE POLICY admin_all ON users
  FOR ALL
  USING (auth.role() = 'service_role');

-- Create invite policies with snake_case column names
CREATE POLICY invites_read_own ON invites
  FOR SELECT
  USING (created_by = auth.uid()::uuid);

CREATE POLICY invites_insert_own ON invites
  FOR INSERT
  WITH CHECK (created_by = auth.uid()::uuid);

CREATE POLICY invites_read_school ON invites
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()::uuid
      AND users.school = invites.school_restriction
    )
  );

CREATE POLICY invites_admin_all ON invites
  FOR ALL
  USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT INSERT ON users TO authenticated;
GRANT SELECT, INSERT ON invites TO authenticated;
