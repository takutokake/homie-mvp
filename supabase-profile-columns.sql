-- Add missing columns to users table for profile functionality
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS "displayName" TEXT,
  ADD COLUMN IF NOT EXISTS "phoneNumber" TEXT,
  ADD COLUMN IF NOT EXISTS "smsConsent" BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS school TEXT,
  ADD COLUMN IF NOT EXISTS neighborhood TEXT,
  ADD COLUMN IF NOT EXISTS "priceRange" TEXT,
  ADD COLUMN IF NOT EXISTS "meetingPreference" TEXT[],
  ADD COLUMN IF NOT EXISTS interests TEXT[],
  ADD COLUMN IF NOT EXISTS "hangoutTypes" TEXT[],
  ADD COLUMN IF NOT EXISTS "preferredTimeOfDay" TEXT[],
  ADD COLUMN IF NOT EXISTS "preferredDays" TEXT[],
  ADD COLUMN IF NOT EXISTS "profileCompleted" BOOLEAN DEFAULT false;

-- Add indices for performance
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school);
CREATE INDEX IF NOT EXISTS idx_users_profile_completed ON users("profileCompleted");
