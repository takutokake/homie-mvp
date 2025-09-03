import jwt from 'jsonwebtoken';
import { randomBytes } from 'crypto';

const JWT_SECRET = process.env.JWT_SECRET!;

if (!JWT_SECRET || JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters long');
}

export interface JWTPayload {
  sub: string; // user id
  jti: string; // jwt id for revocation
  iat: number;
  exp: number;
}

export function signJwt(userId: string): { token: string; jti: string } {
  const jti = randomBytes(16).toString('hex');
  const payload: Omit<JWTPayload, 'iat' | 'exp'> = {
    sub: userId,
    jti,
  };
  
  const token = jwt.sign(payload, JWT_SECRET, {
    expiresIn: '7d',
  });
  
  return { token, jti };
}

export function verifyJwt(token: string): JWTPayload | null {
  try {
    const payload = jwt.verify(token, JWT_SECRET) as JWTPayload;
    return payload;
  } catch (error) {
    return null;
  }
}
