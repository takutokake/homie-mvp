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
    
    if (error || !user) {
      return res.status(401).json({ error: 'invalid_token' });
    }

    // Check if user exists in our database and is active
    const dbUser = await prisma.user.findFirst({
      where: {
        email: user.email,
        isActive: true
      }
    });

    if (!dbUser) {
      return res.status(401).json({ error: 'user_not_found' });
    }

    req.userId = dbUser.id;
    req.user = user;
    next();
  } catch (error) {
    console.error('Token verification error:', error);
    return res.status(401).json({ error: 'invalid_token' });
  }
}
