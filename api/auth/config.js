// Load environment variables
require('dotenv').config();

module.exports = (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  // Return Supabase configuration
  res.status(200).json({
    supabaseUrl: process.env.SUPABASE_URL || 'https://cfmegjvcnsbuyiwvmzft.supabase.co',
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNmbWVnanZjbnNidXlpd3ZtemZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4NzgzNDUsImV4cCI6MjA3MjQ1NDM0NX0.8d2PW5KY1vP2AsYHWUxmHYZydvl5hToanYX8YQV8QgM'
  });
};
