import { config } from 'dotenv';
import express from 'express';
import cors from 'cors';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Load environment variables
config();

// ES modules compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.static('web'));

// Serve Supabase config
app.get('/api/config', (req, res) => {
  const config = {
    supabaseUrl: process.env.SUPABASE_URL,
    supabaseAnonKey: process.env.SUPABASE_ANON_KEY
  };

  if (!config.supabaseUrl || !config.supabaseAnonKey) {
    return res.status(500).json({ error: 'Missing Supabase configuration' });
  }

  res.json(config);
});

// Serve static files
app.get('*', (req, res) => {
  res.sendFile(join(__dirname, 'web', 'index.html'));
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
