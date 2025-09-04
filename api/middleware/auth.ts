import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { prisma } from '../lib/prisma.js';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  user?: any;
}

export async function authenticateToken(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  // Get token from Authorization header
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Please sign in first.' });
  }

  // Handle signup tokens
  if (token.startsWith('SIGNUP_')) {
    // For signup tokens, create a temporary user context
    req.user = { id: 'temp', email: 'temp', isNewSignup: true };
    return next();
  }

  try {
    // Skip Supabase verification for signup tokens
    if (!token.startsWith('SIGNUP_')) {
      const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
      if (error || !user || !user.email) {
        return res.status(401).json({ error: 'Invalid token.' });
      }

      // Look up or create user in database
      let dbUser = await prisma.user.findUnique({
        where: { email: user.email }
      });

      if (!dbUser) {
        // Create new user with temporary values for required fields
        const tempUsername = `user_${Math.random().toString(36).substring(2, 10)}`;
        dbUser = await prisma.user.create({
          data: {
            email: user.email,
            username: tempUsername,
            displayName: tempUsername,
            isActive: true,
            profileCompleted: false
          }
        });
      } else if (!dbUser.isActive) {
        return res.status(401).json({ error: 'user_inactive' });
      }

      req.userId = dbUser.id;
      req.user = user;
    } else {
      // For signup tokens, we already set the user context above
      req.user = { id: 'temp', email: 'temp', isNewSignup: true };
    }
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({ error: 'invalid_token' });
  }
}
