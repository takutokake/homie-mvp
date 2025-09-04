import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../lib/supabase.js';
import { prisma } from '../lib/prisma.js';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  user?: any;
}

export async function authenticateToken(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'access_token_required' });
  }

  try {
    // Verify the Supabase JWT token
    const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);
    
    if (error || !user || !user.email) {
      return res.status(401).json({ error: 'invalid_token' });
    }

    // Get or create user in our database
    let dbUser = await prisma.user.findFirst({
      where: {
        email: user.email
      }
    });

    if (!dbUser) {
      // Create new user with temporary values for required fields
      const tempUsername = `user_${Math.random().toString(36).substring(2, 10)}`;
      dbUser = await prisma.user.create({
        data: {
          email: user.email,
          username: tempUsername,
          displayName: user.email.split('@')[0], // Temporary display name from email
          isActive: true,
          profileCompleted: false
        }
      });
    } else if (!dbUser.isActive) {
      return res.status(401).json({ error: 'user_inactive' });
    }

    req.userId = dbUser.id;
    req.user = user;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({ error: 'invalid_token' });
  }
}
