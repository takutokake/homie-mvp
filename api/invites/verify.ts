import { NextApiRequest, NextApiResponse } from 'next';
import { prisma } from '../lib/prisma';
import { verifyInviteSchema } from '../lib/validators';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { code } = verifyInviteSchema.parse(req.body);
    const codeUpper = code.toUpperCase();

    // Test invite codes for development - bypass database
    const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];
    if (testCodes.includes(codeUpper)) {
      console.log('Valid test code used:', codeUpper);
      return res.json({
        valid: true,
        remaining: 999,
        expiresAt: null
      });
    }

    // For real codes, check database
    let invite;
    try {
      invite = await prisma.invite.findUnique({
        where: { code: codeUpper },
      });
    } catch (dbError) {
      console.error('Database error:', dbError);
      // If database fails, allow test codes as fallback
      if (testCodes.includes(codeUpper)) {
        console.log('Falling back to test code due to DB error:', codeUpper);
        return res.json({
          valid: true,
          remaining: 999,
          expiresAt: null
        });
      }
      throw dbError;
    }

    if (!invite || !invite.isActive) {
      return res.status(404).json({ 
        valid: false, 
        reason: 'invalid' 
      });
    }

    if (invite.expiresAt && invite.expiresAt < new Date()) {
      return res.status(400).json({ 
        valid: false, 
        reason: 'expired' 
      });
    }

    if (invite.usedCount >= invite.maxUses) {
      return res.status(400).json({ 
        valid: false, 
        reason: 'exhausted' 
      });
    }

    return res.json({ 
      valid: true, 
      remaining: invite.maxUses - invite.usedCount, 
      expiresAt: invite.expiresAt 
    });
  } catch (error) {
    console.error('Invite verification error:', error);
    return res.status(500).json({ 
      valid: false, 
      reason: 'error',
      message: 'An unexpected error occurred' 
    });
  }
}
