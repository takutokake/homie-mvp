import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import session from 'express-session';
import passport from 'passport';
import path from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

import { generalLimit } from './middleware/rateLimit';
import authRoutes from './routes/auth';
import inviteRoutes from './routes/invites';
import profileRoutes from './routes/profile';

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3002;
console.log('Starting server on port:', PORT);

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://cdn.tailwindcss.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https:", "http:"]
    }
  }
}));

// CORS configuration
const corsOptions = {
  origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
    const allowedOrigins = [
      'https://homie-mvp-101.vercel.app',
      'http://localhost:3000',
      'http://127.0.0.1:3000'
    ];
    
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) !== -1 || origin.endsWith('.vercel.app')) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
};

app.use(cors(corsOptions));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Session configuration for OAuth
app.use(session({
  secret: process.env.SESSION_SECRET || 'fallback-secret-change-in-production',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production',
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000 // 24 hours
  }
}));

// Passport middleware
app.use(passport.initialize());
app.use(passport.session());

// Rate limiting
app.use(generalLimit);

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/invites', inviteRoutes);
app.use('/api/profile', profileRoutes);

// Supabase auth callback handler
app.get('/auth/v1/callback', (req, res) => {
  const { state, error } = req.query;
  console.log('OAuth callback received:', { state, error });

  if (error) {
    console.error('OAuth callback error:', error);
    res.redirect('/web/login.html?error=' + encodeURIComponent(error.toString()));
    return;
  }

  if (!state) {
    console.error('No state parameter in callback');
    res.redirect('/web/login.html?error=missing_state');
    return;
  }

  // Extract invite code from state parameter
  const [stateValue, inviteCode] = state.toString().split(':');
  if (!inviteCode) {
    console.error('No invite code in state parameter');
    res.redirect('/web/login.html?error=missing_invite_code');
    return;
  }

    // Pass both state and invite code to login page
  const redirectUrl = `/web/login.html?oauth=callback&state=${state}&invite=${inviteCode}`;
  console.log('Redirecting to:', redirectUrl);
  res.redirect(redirectUrl);
});

// Serve static files from web directory
app.use('/web', express.static(path.join(__dirname, '../web')));

// Root redirect to landing page
app.get('/', (req, res) => {
  res.redirect('/web/index.html');
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`🚀 Homie server running on port ${PORT}`);
  console.log(`📱 Web app: http://localhost:${PORT}/web/`);
  console.log(`🔧 API: http://localhost:${PORT}/api/`);
});
