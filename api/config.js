const allowedOrigins = [
  'http://localhost:3000',
  'https://cfmegjvcnsbuyiwvmzft.supabase.co'
];

module.exports = (req, res) => {
  const origin = req.headers.origin;
  if (allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // Return Supabase configuration from environment variables
  const config = {
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY
  };

  // Validate config
  if (!config.supabaseUrl || !config.supabaseAnonKey) {
    return res.status(500).json({ error: 'Missing Supabase configuration' });
  }

  return res.status(200).json(config);
};
