const { PrismaClient } = require('@prisma/client');

// Test invite codes for development - bypass database
const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];

let prisma;

module.exports = async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { code } = req.body;
    
    if (!code) {
      return res.status(400).json({ valid: false, reason: 'missing_code' });
    }

    const codeUpper = code.toUpperCase();

    // Check test codes first - always allow these
    if (testCodes.includes(codeUpper)) {
      console.log('Valid test code used:', codeUpper);
      return res.json({
        valid: true,
        remaining: 999,
        expiresAt: null
      });
    }

    // Initialize Prisma client if not already done
    if (!prisma) {
      try {
        prisma = new PrismaClient();
      } catch (prismaError) {
        console.error('Failed to initialize Prisma:', prismaError);
        return res.status(500).json({ 
          valid: false, 
          reason: 'database_unavailable',
          message: 'Database connection failed' 
        });
      }
    }

    // For real codes, check database
    let invite;
    try {
      invite = await prisma.invite.findUnique({
        where: { code: codeUpper },
      });
    } catch (dbError) {
      console.error('Database query error:', dbError);
      return res.status(500).json({ 
        valid: false, 
        reason: 'database_error',
        message: 'Failed to verify invite code' 
      });
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
