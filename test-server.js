import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

// Serve static files from web directory
app.use('/web', express.static(path.join(__dirname, 'web')));

// Root redirect to landing page
app.get('/', (req, res) => {
  res.redirect('/web/index.html');
});

app.listen(PORT, () => {
  console.log(`🚀 Test server running on port ${PORT}`);
  console.log(`📱 Web app: http://localhost:${PORT}/web/`);
});
