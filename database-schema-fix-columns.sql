-- Rename camelCase columns to snake_case
ALTER TABLE users 
  RENAME COLUMN "smsConsent" TO sms_consent;

ALTER TABLE users 
  RENAME COLUMN "profileCompleted" TO profile_completed;

ALTER TABLE users 
  RENAME COLUMN "displayName" TO display_name;

ALTER TABLE users 
  RENAME COLUMN "phoneNumber" TO phone_number;

ALTER TABLE users 
  RENAME COLUMN "priceRange" TO price_range;

ALTER TABLE users 
  RENAME COLUMN "preferredTimeOfDay" TO preferred_time_of_day;

ALTER TABLE users 
  RENAME COLUMN "preferredDays" TO preferred_days;

ALTER TABLE users 
  RENAME COLUMN "meetingPreference" TO meeting_preference;

ALTER TABLE users 
  RENAME COLUMN "isActive" TO is_active;

ALTER TABLE users 
  RENAME COLUMN "createdAt" TO created_at;

ALTER TABLE users 
  RENAME COLUMN "updatedAt" TO updated_at;

-- Update invites table columns
ALTER TABLE invites 
  RENAME COLUMN "createdBy" TO created_by;

ALTER TABLE invites 
  RENAME COLUMN "maxUses" TO max_uses;

ALTER TABLE invites 
  RENAME COLUMN "usedCount" TO used_count;

ALTER TABLE invites 
  RENAME COLUMN "expiresAt" TO expires_at;

ALTER TABLE invites 
  RENAME COLUMN "isActive" TO is_active;

ALTER TABLE invites 
  RENAME COLUMN "schoolRestriction" TO school_restriction;

ALTER TABLE invites 
  RENAME COLUMN "inviteType" TO invite_type;

ALTER TABLE invites 
  RENAME COLUMN "createdAt" TO created_at;
