-- Drop existing tables first to ensure clean setup
DROP TABLE IF EXISTS meetup_participants CASCADE;
DROP TABLE IF EXISTS meetups CASCADE;
DROP TABLE IF EXISTS user_connections CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS invites CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table linked to auth.users
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    "displayName" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    school TEXT,
    neighborhood TEXT,
    "priceRange" TEXT,
    interests TEXT[] DEFAULT '{}',
    "hangoutTypes" TEXT[] DEFAULT '{}',
    "preferredTimeOfDay" TEXT[] DEFAULT '{}',
    "preferredDays" TEXT[] DEFAULT '{}',
    "meetingPreference" TEXT[] DEFAULT '{}',
    "profileCompleted" BOOLEAN DEFAULT false,
    "isActive" BOOLEAN DEFAULT true,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "lastLogin" TIMESTAMP WITH TIME ZONE
);

-- Invites table
CREATE TABLE invites (
    code TEXT PRIMARY KEY,
    "createdBy" UUID NOT NULL REFERENCES users(id),
    "maxUses" INTEGER DEFAULT 1,
    "usedCount" INTEGER DEFAULT 0,
    "expiresAt" TIMESTAMP WITH TIME ZONE,
    "isActive" BOOLEAN DEFAULT true,
    "schoolRestriction" TEXT,
    "inviteType" TEXT DEFAULT 'general',
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "jwtId" TEXT UNIQUE NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "revokedAt" TIMESTAMP WITH TIME ZONE
);

-- User connections table
CREATE TABLE user_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "user1Id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "user2Id" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "connectionType" TEXT DEFAULT 'match',
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE("user1Id", "user2Id")
);

-- Meetups table
CREATE TABLE meetups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "createdBy" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT NOT NULL,
    "priceRange" TEXT NOT NULL,
    "cuisineType" TEXT,
    "maxParticipants" INTEGER DEFAULT 4,
    "currentParticipants" INTEGER DEFAULT 1,
    "scheduledFor" TIMESTAMP WITH TIME ZONE NOT NULL,
    status TEXT DEFAULT 'open',
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Meetup participants table
CREATE TABLE meetup_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "meetupId" UUID NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    "userId" UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "joinedAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    status TEXT DEFAULT 'confirmed',
    UNIQUE("meetupId", "userId")
);

-- Note: Test invite codes will be created after first user signs up
-- Cannot insert invites without a real user ID from auth.users

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
