-- Create tables for Homie application in Supabase
-- Run this in your Supabase SQL Editor

-- Drop existing tables first to ensure clean setup
DROP TABLE IF EXISTS meetup_participants CASCADE;
DROP TABLE IF EXISTS meetups CASCADE;
DROP TABLE IF EXISTS user_connections CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS invites CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    "passwordHash" TEXT,
    "googleId" TEXT UNIQUE,
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
    "createdBy" TEXT NOT NULL,
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
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "jwtId" TEXT UNIQUE NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    "revokedAt" TIMESTAMP WITH TIME ZONE
);

-- User connections table
CREATE TABLE user_connections (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "user1Id" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "user2Id" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "connectionType" TEXT DEFAULT 'match',
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE("user1Id", "user2Id")
);

-- Meetups table
CREATE TABLE meetups (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "createdBy" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    "meetupId" TEXT NOT NULL REFERENCES meetups(id) ON DELETE CASCADE,
    "userId" TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    "joinedAt" TIMESTAMP WITH TIME ZONE DEFAULT now(),
    status TEXT DEFAULT 'confirmed',
    UNIQUE("meetupId", "userId")
);

-- Insert some test invite codes
INSERT INTO invites (code, "createdBy", "maxUses", "usedCount", "isActive", "inviteType") 
VALUES 
    ('TEST01', 'admin', 999, 0, true, 'test'),
    ('TEST02', 'admin', 999, 0, true, 'test'),
    ('DEMO01', 'admin', 999, 0, true, 'test'),
    ('DEMO02', 'admin', 999, 0, true, 'test'),
    ('DEV001', 'admin', 999, 0, true, 'test'),
    ('HOMIE1', 'admin', 999, 0, true, 'test'),
    ('INVITE', 'admin', 999, 0, true, 'test');

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

-- Enable Row Level Security (RLS) for all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE meetup_participants ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users
CREATE POLICY "Users can view their own data" ON users
    FOR ALL USING (auth.uid()::text = id);

CREATE POLICY "Anyone can read invites" ON invites
    FOR SELECT USING (true);

CREATE POLICY "Users can manage their own sessions" ON sessions
    FOR ALL USING (auth.uid()::text = "userId");

-- Add more policies as needed for your app's security requirements
