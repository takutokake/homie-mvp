import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { supabaseAdmin, supabaseConfig } from '../lib/supabase.js';
import { signupSchema, completeProfileSchema } from '../lib/validators.js';
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
      username, email, password, code,
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

      // Create user in Supabase Auth
      const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          username,
          displayName
        }
      });

      if (authError || !authData.user) {
        if (authError?.message?.includes('already registered')) {
          throw new Error('email_taken');
        }
        throw new Error('auth_creation_failed');
      }

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

router.post('/login', signupLimit, async (req, res) => {
  try {
    const { email, password } = signupSchema.parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email }
    });

    if (!user || !user.passwordHash) {
      return res.status(401).json({ error: 'invalid_credentials' });
    }

    const isValidPassword = await bcrypt.compare(password, user.passwordHash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'invalid_credentials' });
    }

    // Create new session
    const { token, jti } = signJwt(user.id);
    await prisma.session.create({
      data: {
        userId: user.id,
        jwtId: jti
      }
    });

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    return res.status(500).json({ error: 'login_failed' });
  }
});

router.get('/google', (req, res, next) => {
  // Store invite code in session if provided
  const inviteCode = req.query.invite as string;
  if (inviteCode && /^[A-Z0-9]{6}$/.test(inviteCode)) {
    req.session.inviteCode = inviteCode.toUpperCase();
  }
  
  passport.authenticate('google', { scope: ['profile', 'email'] })(req, res, next);
});

router.get('/google/callback', 
  passport.authenticate('google', { session: false }),
  async (req, res) => {
    try {
      const googleUser = req.user as any;
      
      if (!googleUser.isNewUser) {
        // Existing user - create session and redirect
        const { token, jti } = signJwt(googleUser.id);
        await prisma.session.create({
          data: {
            userId: googleUser.id,
            jwtId: jti
          }
        });
        
        return res.redirect(`/web/?token=${token}`);
      }

      // New user - need invite code and profile completion
      const inviteCode = req.session.inviteCode;
      if (!inviteCode) {
        return res.redirect('/web/signup.html?error=invite_required');
      }

      await prisma.$transaction(async (tx) => {
        // Verify invite
        const invite = await tx.invite.findUnique({
          where: { code: inviteCode }
        });
        if (!invite || !invite.isActive || (invite.expiresAt && invite.expiresAt < new Date()) || invite.usedCount >= invite.maxUses) {
          throw new Error('invalid_invite');
        }
        
        // Create user with minimal profile (needs completion)
        const user = await tx.user.create({
          data: {
            email: googleUser.email,
            username: googleUser.email.split('@')[0],
            googleId: googleUser.googleId,
            displayName: googleUser.email.split('@')[0], // Temporary display name
            profileCompleted: false, // Requires profile completion
            lastLogin: new Date()
          }
        });
        
        await tx.invite.update({
          where: { code: inviteCode },
          data: { usedCount: { increment: 1 } }
        });
        
        const { token, jti } = signJwt(user.id);
        await tx.session.create({
          data: { userId: user.id, jwtId: jti }
        });
        
        delete req.session.inviteCode;
        
        // Redirect to profile completion page
        res.redirect(`/web/complete-profile.html?token=${token}`);
      });
    } catch (error: any) {
      console.error('Google OAuth callback error:', error);
      if (error.message === 'invalid_invite') {
        return res.redirect('/web/signup.html?error=invalid_invite');
      }
      return res.redirect('/web/signup.html?error=oauth_failed');
    }
  }
);

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

// Logout (handled by Supabase on frontend)
router.post('/logout', (req, res) => {
  res.json({ message: 'Logout handled by Supabase client' });
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

export default router;
