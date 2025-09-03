import { z } from 'zod';

export const inviteCodeSchema = z.string().regex(/^[A-Z0-9]{6}$/, 'Invalid invite code format');

export const signupSchema = z.object({
  username: z.string().min(3).max(20).regex(/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'),
  email: z.string().email('Invalid email format'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  code: inviteCodeSchema,
  
  // Profile information
  displayName: z.string().min(1).max(50, 'Display name must be 1-50 characters'),
  phoneNumber: z.string().optional().nullable(),
  school: z.enum(['USC', 'UCLA'], { errorMap: () => ({ message: 'School must be USC or UCLA' }) }),
  locationDetails: z.string().optional().nullable(),
  priceRange: z.enum(['$', '$$', '$$$', '$$$$'], { errorMap: () => ({ message: 'Invalid price range' }) }),
  meetingPreference: z.array(z.enum(['coffee', 'lunch', 'dinner', 'study', 'casual', 'activity'])).default([]),
  interests: z.array(z.string()).default([]),
  cuisinePreferences: z.array(z.string()).default([]),
});

export const loginSchema = z.object({
  email: z.string().email('Invalid email format'),
  password: z.string().min(1, 'Password is required'),
});

export const verifyInviteSchema = z.object({
  code: inviteCodeSchema,
});

export const completeProfileSchema = z.object({
  displayName: z.string().min(1).max(50, 'Display name must be 1-50 characters'),
  phoneNumber: z.string().optional().nullable(),
  school: z.enum(['USC', 'UCLA'], { errorMap: () => ({ message: 'School must be USC or UCLA' }) }),
  locationDetails: z.string().optional().nullable(),
  priceRange: z.enum(['$', '$$', '$$$', '$$$$'], { errorMap: () => ({ message: 'Invalid price range' }) }),
  meetingPreference: z.array(z.enum(['coffee', 'lunch', 'dinner', 'study', 'casual', 'activity'])).default([]),
  interests: z.array(z.string()).default([]),
  cuisinePreferences: z.array(z.string()).default([]),
});

export function validatePassword(password: string): { isValid: boolean; reason?: string } {
  if (password.length < 8) {
    return { isValid: false, reason: 'Password must be at least 8 characters' };
  }
  
  // Basic entropy check - require at least 2 different character types
  const hasLower = /[a-z]/.test(password);
  const hasUpper = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[^a-zA-Z0-9]/.test(password);
  
  const typeCount = [hasLower, hasUpper, hasNumber, hasSpecial].filter(Boolean).length;
  
  if (typeCount < 2) {
    return { isValid: false, reason: 'Password must contain at least 2 different character types (lowercase, uppercase, numbers, special characters)' };
  }
  
  return { isValid: true };
}
