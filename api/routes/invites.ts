import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { verifyInviteSchema } from '../lib/validators';
import { inviteVerifyLimit } from '../middleware/rateLimit';

const router = Router();

router.post('/verify', inviteVerifyLimit, async (req, res) => {
  try {
    const { code } = verifyInviteSchema.parse(req.body);
    const codeUpper = code.toUpperCase();

    // Test invite codes for development - bypass database
    const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];
    if (testCodes.includes(codeUpper)) {
      return res.json({
        valid: true,
        remaining: 999,
        expiresAt: null
      });
    }

    try {
      const invite = await prisma.invite.findUnique({
        where: { code: codeUpper },
      });

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
    } catch (dbError) {
      // If database fails, fall back to invalid for non-test codes
      console.error('Database error during invite verification:', dbError);
      return res.status(404).json({ 
        valid: false, 
        reason: 'invalid' 
      });
    }
  } catch (error) {
    console.error('Invite verification error:', error);
    return res.status(400).json({ 
      valid: false, 
      reason: 'invalid' 
    });
  }
});

export default router;
