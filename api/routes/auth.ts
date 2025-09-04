import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { supabaseAdmin, supabaseConfig } from '../lib/supabase';
import { signupSchema, completeProfileSchema } from '../lib/validators';
import { signupLimit } from '../middleware/rateLimit';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';

const router = Router();

// Get Supabase configuration for frontend
router.get('/config', (req, res) => {
  res.json({
    supabaseUrl: supabaseConfig.url,
    supabaseAnonKey: supabaseConfig.anonKey
  });
});

// Database verification endpoint
router.get('/db-status', async (req, res) => {
  try {
    // Test database connection
    const userCount = await prisma.user.count();
    const inviteCount = await prisma.invite.count();
    
    res.json({
      status: 'connected',
      userCount,
      inviteCount,
      timestamp: new Date().toISOString()
    });
  } catch (error: any) {
    console.error('Database connection error:', error);
    res.status(500).json({
      status: 'error',
      error: error.message || 'Database connection failed',
      timestamp: new Date().toISOString()
    });
  }
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

    // Handle test codes without database check
    const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];
    let isTestCode = testCodes.includes(codeUpper);

    if (!isTestCode) {
      // Only check database for non-test codes
      try {
        const invite = await prisma.invite.findUnique({
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
      } catch (dbError: any) {
        console.error('Database error during signup:', dbError);
        throw new Error('invalid_invite');
      }
    }

    try {
      // Check if username already exists
      const existingUser = await prisma.user.findFirst({
        where: { username }
      });

      if (existingUser) {
        throw new Error('username_taken');
      }

      // Create user profile in database
      const user = await prisma.user.create({
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

      // Consume invite (only for non-test codes)
      if (!isTestCode) {
        await prisma.invite.update({
          where: { code: codeUpper },
          data: { usedCount: { increment: 1 } }
        });
      }

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
    } catch (dbError: any) {
      console.error('Database error during user creation:', dbError);
      // For now, return success for test codes even if DB fails
      if (isTestCode) {
        res.json({
          message: 'User created successfully (test mode)',
          user: {
            id: 'test-user-' + Date.now(),
            email,
            username,
            displayName,
            school,
            profileCompleted: true
          }
        });
      } else {
        throw dbError;
      }
    }
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
  console.log('Received OAuth callback request:', { body: req.body });
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  try {
    const { user: authUser, code } = req.body;
    if (!authUser) {
      console.error('Missing user data in OAuth callback');
      return res.status(400).json({ error: 'missing_user_data' });
    }
    if (!code) {
      console.error('Missing invite code in OAuth callback');
      return res.status(400).json({ error: 'missing_invite_code' });
    }

    // Handle test invite codes
    const codeUpper = code.toUpperCase();
    const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];
    if (testCodes.includes(codeUpper)) {
      return res.json({
        user: {
          id: 'test-user',
          email: authUser.email,
          username: authUser.email.split('@')[0],
          displayName: authUser.user_metadata?.full_name || authUser.email.split('@')[0],
          profileCompleted: false
        },
        needsProfileCompletion: true
      });
    }

    // For non-test codes, use transaction
    const transactionResult = await prisma.$transaction(async (tx) => {
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
        
        return {
          user: {
            id: existingUser.id,
            email: existingUser.email,
            username: existingUser.username,
            displayName: existingUser.displayName,
            profileCompleted: existingUser.profileCompleted
          },
          needsProfileCompletion: false
        };
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

      return {
        user: {
          id: user.id,
          email: user.email,
          username: user.username,
          displayName: user.displayName,
          profileCompleted: user.profileCompleted
        },
        needsProfileCompletion: true
      };
    });

    return res.json(transactionResult);
  } catch (error: any) {
    console.error('OAuth callback error:', error);
    console.error('Error details:', {
      message: error.message,
      code: error.code,
      stack: error.stack
    });
    
    if (error?.message === 'invalid_invite') {
      return res.status(400).json({ error: 'invalid_invite' });
    }
    if (error?.message === 'missing_user_data') {
      return res.status(400).json({ error: 'missing_user_data' });
    }
    if (error?.message === 'missing_invite_code') {
      return res.status(400).json({ error: 'missing_invite_code' });
    }
    
    return res.status(500).json({ 
      error: 'oauth_callback_failed',
      details: error.message
    });
  }
});

// Complete profile for OAuth users
router.post('/complete-profile', authenticateToken, async (req: AuthenticatedRequest, res) => {
  try {
    const validatedData = completeProfileSchema.parse(req.body);
    const { 
      displayName, phoneNumber, school, locationDetails, 
      priceRange, meetingPreference, interests, cuisinePreferences 
    } = validatedData;

    // Update user profile
    const user = await prisma.user.update({
      where: { id: req.userId },
      data: {
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
  } catch (error: any) {
    console.error('Complete profile error:', error);
    return res.status(500).json({ error: 'profile_completion_failed' });
  }
});

// Logout (handled by Supabase on frontend)
router.post('/logout', (req, res) => {
  res.json({ message: 'Logout handled by Supabase client' });
});

export default router;
