import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { supabaseAdmin, supabaseConfig } from '../lib/supabase.js';
import { signupSchema } from '../lib/validators.js';
import { signupLimit } from '../middleware/rateLimit.js';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth.js';

const router = Router();

// Get Supabase configuration for frontend
router.get('/config', (req, res) => {
  res.json({
    supabaseUrl: supabaseConfig.url,
    supabaseAnonKey: supabaseConfig.anonKey
  });
});

// Signup with invite code validation
router.post('/signup', signupLimit, async (req, res) => {
  try {
    const validatedData = signupSchema.parse(req.body);
    const { 
      username, email, code,
      displayName, phoneNumber, school, locationDetails, 
      priceRange, meetingPreference, interests, cuisinePreferences 
    } = validatedData;

    const codeUpper = code.toUpperCase();

    await prisma.$transaction(async (tx) => {
      // Check invite validity
      const invite = await tx.invite.findUnique({
        where: { code: codeUpper }
      });

      if (!invite || !invite.isActive) {
        throw new Error('invalid_invite');
      }
      if (invite.expiresAt && invite.expiresAt < new Date()) {
        throw new Error('invalid_invite');
      }
      if (invite.usedCount >= invite.maxUses) {
        throw new Error('invalid_invite');
      }

      // Check school restriction
      if (invite.schoolRestriction && invite.schoolRestriction !== 'BOTH' && invite.schoolRestriction !== school) {
        throw new Error('school_restricted');
      }

      // Check if username already exists in our database
      const existingUser = await tx.user.findFirst({
        where: { username }
      });

      if (existingUser) {
        throw new Error('username_taken');
      }

      // Note: User is already created in Supabase Auth by frontend
      // We just need to verify they exist and create the profile

      // Create user profile in our database
      const user = await tx.user.create({
        data: {
          email,
          username,
          displayName,
          phoneNumber,
          school,
          locationDetails,
          priceRange,
          meetingPreference,
          interests,
          cuisinePreferences,
          profileCompleted: true,
          lastLogin: new Date()
        }
      });

      // Consume invite
      await tx.invite.update({
        where: { code: codeUpper },
        data: { usedCount: { increment: 1 } }
      });

      res.json({
        message: 'User created successfully',
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          school: user.school,
          profileCompleted: user.profileCompleted
        }
      });
    });
  } catch (error: any) {
    console.error('Signup error:', error);
    
    if (error.message === 'invalid_invite') {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    if (error.message === 'school_restricted') {
      return res.status(400).json({ error: 'school_restricted' });
    }
    if (error.message === 'email_taken') {
      return res.status(409).json({ error: 'email_taken' });
    }
    if (error.message === 'username_taken') {
      return res.status(409).json({ error: 'username_taken' });
    }
    
    return res.status(500).json({ error: 'signup_failed' });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req: AuthenticatedRequest, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      select: {
        id: true,
        email: true,
        username: true,
        displayName: true,
        school: true,
        profileCompleted: true,
        createdAt: true,
        lastLogin: true
      }
    });

    if (!user) {
      return res.status(404).json({ error: 'user_not_found' });
    }

    res.json({ user });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'fetch_user_failed' });
  }
});

// Handle OAuth callback and create user profile
router.post('/oauth-callback', async (req, res) => {
  try {
    const { user: authUser, code } = req.body;
    
    if (!authUser || !code) {
      return res.status(400).json({ error: 'missing_required_data' });
    }

    const codeUpper = code.toUpperCase();

    await prisma.$transaction(async (tx) => {
      // Check invite validity
      const invite = await tx.invite.findUnique({
        where: { code: codeUpper }
      });

      if (!invite || !invite.isActive) {
        throw new Error('invalid_invite');
      }
      if (invite.expiresAt && invite.expiresAt < new Date()) {
        throw new Error('invalid_invite');
      }
      if (invite.usedCount >= invite.maxUses) {
        throw new Error('invalid_invite');
      }

      // Check if user already exists in our database
      const existingUser = await tx.user.findFirst({
        where: { email: authUser.email }
      });

      if (existingUser) {
        // Update last login
        await tx.user.update({
          where: { id: existingUser.id },
          data: { lastLogin: new Date() }
        });
        
        return res.json({
          user: {
            id: existingUser.id,
            email: existingUser.email,
            username: existingUser.username,
            displayName: existingUser.displayName,
            profileCompleted: existingUser.profileCompleted
          }
        });
      }

      // Create new user profile (needs completion)
      const user = await tx.user.create({
        data: {
          email: authUser.email,
          username: authUser.email.split('@')[0],
          displayName: authUser.user_metadata?.full_name || authUser.email.split('@')[0],
          profileCompleted: false,
          lastLogin: new Date()
        }
      });

      // Consume invite
      await tx.invite.update({
        where: { code: codeUpper },
        data: { usedCount: { increment: 1 } }
      });

      res.json({
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          profileCompleted: user.profileCompleted
        },
        needsProfileCompletion: true
      });
    });
  } catch (error: any) {
    console.error('OAuth callback error:', error);
    
    if (error.message === 'invalid_invite') {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    
    return res.status(500).json({ error: 'oauth_callback_failed' });
  }
});

// Sign in with email/password
router.post('/signin', async (req, res) => {
  try {
    const { email, code } = req.body;
    
    if (!email || !code) {
      return res.status(400).json({ error: 'missing_required_data' });
    }

    const codeUpper = code.toUpperCase();

    // Check invite validity
    const invite = await prisma.invite.findUnique({
      where: { code: codeUpper }
    });

    if (!invite || !invite.isActive) {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    if (invite.expiresAt && invite.expiresAt < new Date()) {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    if (invite.usedCount >= invite.maxUses) {
      return res.status(400).json({ error: 'invalid_invite' });
    }

    // Check if user exists in our database
    const user = await prisma.user.findFirst({
      where: { email }
    });

    if (user) {
      // Update last login
      await prisma.user.update({
        where: { id: user.id },
        data: { lastLogin: new Date() }
      });
      
      return res.json({
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          profileCompleted: user.profileCompleted
        },
        needsProfileCompletion: !user.profileCompleted
      });
    } else {
      // User doesn't exist in our database, they need to create account
      return res.json({
        needsProfileCompletion: true
      });
    }
  } catch (error: any) {
    console.error('Sign in error:', error);
    return res.status(500).json({ error: 'signin_failed' });
  }
});

// Complete profile for new users (no auth required since they're creating account)
router.post('/complete-profile', async (req, res) => {
  try {
    const { 
      username, code, email, displayName, phoneNumber, school, locationDetails, 
      priceRange, meetingPreference, interests, cuisinePreferences 
    } = req.body;

    if (!username || !code) {
      return res.status(400).json({ error: 'missing_required_data' });
    }

    const codeUpper = code.toUpperCase();

    await prisma.$transaction(async (tx) => {
      // Check invite validity
      const invite = await tx.invite.findUnique({
        where: { code: codeUpper }
      });

      if (!invite || !invite.isActive) {
        throw new Error('invalid_invite');
      }
      if (invite.expiresAt && invite.expiresAt < new Date()) {
        throw new Error('invalid_invite');
      }
      if (invite.usedCount >= invite.maxUses) {
        throw new Error('invalid_invite');
      }

      // Check school restriction
      if (invite.schoolRestriction && invite.schoolRestriction !== 'BOTH' && invite.schoolRestriction !== school) {
        throw new Error('school_restricted');
      }

      // Check if username already exists
      const existingUser = await tx.user.findFirst({
        where: { username }
      });

      if (existingUser) {
        throw new Error('username_taken');
      }

      // Get email from request body (passed from frontend)
      const { email } = req.body;
      
      if (!email) {
        throw new Error('email_required');
      }
      
      // Check if email already exists
      const existingEmailUser = await tx.user.findFirst({
        where: { email }
      });

      if (existingEmailUser) {
        throw new Error('email_taken');
      }
      
      const user = await tx.user.create({
        data: {
          email,
          username,
          displayName,
          phoneNumber,
          school,
          locationDetails,
          priceRange,
          meetingPreference,
          interests,
          cuisinePreferences,
          profileCompleted: true,
          lastLogin: new Date()
        }
      });

      // Consume invite
      await tx.invite.update({
        where: { code: codeUpper },
        data: { usedCount: { increment: 1 } }
      });

      res.json({
        message: 'Profile completed successfully',
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          school: user.school,
          profileCompleted: user.profileCompleted
        }
      });
    });
  } catch (error: any) {
    console.error('Complete profile error:', error);
    
    if (error.message === 'invalid_invite') {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    if (error.message === 'school_restricted') {
      return res.status(400).json({ error: 'school_restricted' });
    }
    if (error.message === 'username_taken') {
      return res.status(409).json({ error: 'username_taken' });
    }
    if (error.message === 'email_taken') {
      return res.status(409).json({ error: 'email_taken' });
    }
    if (error.message === 'email_required') {
      return res.status(400).json({ error: 'email_required' });
    }
    
    return res.status(500).json({ error: 'profile_completion_failed' });
  }
});

// Logout (handled by Supabase on frontend)
router.post('/logout', (req, res) => {
  res.json({ message: 'Logout handled by Supabase client' });
});

export default router;
