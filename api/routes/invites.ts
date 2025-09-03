import { Router } from 'express';
import { prisma } from '../lib/prisma.js';
import { verifyInviteSchema } from '../lib/validators.js';
import { inviteVerifyLimit } from '../middleware/rateLimit.js';

const router = Router();

router.post('/verify', inviteVerifyLimit, async (req, res) => {
  try {
    const { code } = verifyInviteSchema.parse(req.body);
    const codeUpper = code.toUpperCase();

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
  } catch (error) {
    console.error('Invite verification error:', error);
    return res.status(400).json({ 
      valid: false, 
      reason: 'invalid' 
    });
  }
});

export default router;
