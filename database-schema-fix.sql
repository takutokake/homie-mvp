-- Add new columns to users table
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS username VARCHAR(255),
  ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sms_consent BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS school_area TEXT,
  ADD COLUMN IF NOT EXISTS interests TEXT[],
  ADD COLUMN IF NOT EXISTS vibe TEXT[];

-- Create interests enum (only if it doesn't exist)
DO $$ BEGIN
    CREATE TYPE user_interest AS ENUM (
      'technology', 'arts', 'sports', 'music', 'travel', 'food',
      'photography', 'gaming', 'fitness', 'movies', 'startups', 
      'business', 'politics', 'health', 'science', 'fashion',
      'dance', 'cooking', 'culinary', 'gardening'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create vibe categories enum (only if it doesn't exist)
DO $$ BEGIN
    CREATE TYPE user_vibe AS ENUM (
      'adventurous', 'creative', 'intellectual', 'social', 'athletic',
      'foodie', 'entrepreneurial', 'artistic', 'tech_savvy', 'outdoorsy',
      'professional', 'casual', 'academic'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Update existing price_range type if needed
ALTER TABLE users 
  DROP COLUMN IF EXISTS price_range;
ALTER TABLE users 
  ADD COLUMN price_range VARCHAR(4) CHECK (price_range IN ('$', '$$', '$$$', '$$$$'));

-- Add indices for new searchable columns
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_school_area ON users(school_area);
CREATE INDEX IF NOT EXISTS idx_users_interests ON users USING GIN(interests);
CREATE INDEX IF NOT EXISTS idx_users_vibe ON users USING GIN(vibe);
