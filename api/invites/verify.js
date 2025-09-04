// Test invite codes for development - bypass database
const testCodes = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];

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
    console.log('Received request body:', req.body);
    const { code } = req.body;
    
    if (!code) {
      console.log('No code provided in request');
      return res.status(400).json({ valid: false, reason: 'missing_code' });
    }

    const codeUpper = code.toUpperCase();
    console.log('Processing invite code:', codeUpper);

    // Check test codes first - always allow these
    if (testCodes.includes(codeUpper)) {
      console.log('Valid test code used:', codeUpper);
      return res.json({
        valid: true,
        remaining: 999,
        expiresAt: null
      });
    }

    console.log('Code not in test codes:', codeUpper);
    
    // For now, reject non-test codes since database connection is problematic
    return res.status(404).json({ 
      valid: false, 
      reason: 'invalid' 
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
