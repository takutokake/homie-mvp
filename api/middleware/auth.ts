import { Request, Response, NextFunction } from 'express';
import { verifyJwt } from '../lib/jwt.js';
import { prisma } from '../lib/prisma.js';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
    email: string;
    username: string;
  };
}

export async function authenticateToken(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  const payload = verifyJwt(token);
  if (!payload) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  // Check if session is still valid (not revoked)
  const session = await prisma.session.findUnique({
    where: { jwtId: payload.jti },
    include: { user: true },
  });

  if (!session || session.revokedAt) {
    return res.status(401).json({ error: 'Session revoked or invalid' });
  }

  req.user = {
    id: session.user.id,
    email: session.user.email,
    username: session.user.username,
  };

  next();
}
