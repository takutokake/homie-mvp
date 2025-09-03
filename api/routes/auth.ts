import { Router } from 'express';
import bcrypt from 'bcrypt';
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { prisma } from '../lib/prisma.js';
import { signJwt } from '../lib/jwt.js';
import { signupSchema, loginSchema, validatePassword, completeProfileSchema } from '../lib/validators.js';
import { signupLimit, loginLimit } from '../middleware/rateLimit.js';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth.js';

const router = Router();

// Configure Google OAuth strategy
passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  callbackURL: process.env.GOOGLE_CALLBACK_URL!,
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const email = profile.emails?.[0]?.value;
    const googleId = profile.id;
    
    if (!email) {
      return done(new Error('No email from Google'), null);
    }

    // Check if user exists by googleId or email
    let user = await prisma.user.findFirst({
      where: {
        OR: [
          { googleId },
          { email }
        ]
      }
    });

    if (user) {
      // Update googleId if user exists but doesn't have it set
      if (!user.googleId) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: { googleId }
        });
      }
      return done(null, user);
    }

    // For new users, we need an invite code stored in session
    return done(null, { email, googleId, isNewUser: true });
  } catch (error) {
    return done(error, null);
  }
}));

router.post('/signup', signupLimit, async (req, res) => {
  try {
    const validatedData = signupSchema.parse(req.body);
    const { 
      username, email, password, code,
      displayName, phoneNumber, school, locationDetails, 
      priceRange, meetingPreference, interests, cuisinePreferences 
    } = validatedData;
    
    // Validate password strength
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({ error: 'weak_password', message: passwordValidation.reason });
    }

    const codeUpper = code.toUpperCase();

    await prisma.$transaction(async (tx) => {
      // Check invite validity with row lock
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

      // Check if email or username already exists
      const existingUser = await tx.user.findFirst({
        where: {
          OR: [
            { email },
            { username }
          ]
        }
      });

      if (existingUser) {
        if (existingUser.email === email) {
          throw new Error('email_taken');
        }
        if (existingUser.username === username) {
          throw new Error('username_taken');
        }
      }

      // Create user with full profile
      const passwordHash = await bcrypt.hash(password, 12);
      const user = await tx.user.create({
        data: {
          email,
          username,
          passwordHash,
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

      // Create session
      const { token, jti } = signJwt(user.id);
      await tx.session.create({
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

router.post('/login', loginLimit, async (req, res) => {
  try {
    const { email, password } = loginSchema.parse(req.body);

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

router.get('/me', authenticateToken, async (req: AuthenticatedRequest, res) => {
  res.json(req.user);
});

router.post('/logout', authenticateToken, async (req: AuthenticatedRequest, res) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader?.split(' ')[1];
    
    if (token) {
      const payload = require('../lib/jwt.js').verifyJwt(token);
      if (payload) {
        // Revoke the session
        await prisma.session.update({
          where: { jwtId: payload.jti },
          data: { revokedAt: new Date() }
        });
      }
    }
    
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'logout_failed' });
  }
});

// Complete profile for Google OAuth users
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
