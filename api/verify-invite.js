// Simple invite verification - no dependencies
const VALID_CODES = ['TEST01', 'TEST02', 'DEMO01', 'DEMO02', 'DEV001', 'HOMIE1', 'INVITE'];

module.exports = (req, res) => {
  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { code } = req.body || {};
  
  if (!code) {
    return res.status(400).json({ 
      valid: false, 
      reason: 'missing_code' 
    });
  }

  const codeUpper = code.toString().toUpperCase().trim();
  
  if (VALID_CODES.includes(codeUpper)) {
    return res.status(200).json({
      valid: true,
      remaining: 999,
      expiresAt: null
    });
  }

  return res.status(404).json({
    valid: false,
    reason: 'invalid'
  });
};
