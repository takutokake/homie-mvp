# Homie MVP - Never Meet Alone

A social platform where every hangout happens through friends of friends, built with invite-only access.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL database
- Google OAuth credentials (optional, for Google sign-in)

### Setup

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your database URL and other settings
   ```

3. **Set up database**
   ```bash
   # Push schema to database
   npm run db:push
   
   # Or run migrations (for production)
   npm run db:migrate
   ```

4. **Create invite codes**
   ```bash
   # Create a single-use invite
   npx tsx scripts/create-invite.ts
   
   # Create multi-use invite
   npx tsx scripts/create-invite.ts -- --max-uses 5
   
   # Create expiring invite
   npx tsx scripts/create-invite.ts -- --max-uses 3 --expires "2024-12-31T23:59:59Z"
   ```

5. **Start the server**
   ```bash
   npm run dev
   ```

6. **Visit the app**
   - Landing page: http://localhost:3000/web/
   - Sign up: http://localhost:3000/web/signup.html

## 📋 API Endpoints

### Invites
- `POST /api/invites/verify` - Verify invite code validity

### Authentication
- `POST /api/auth/signup` - Create account with email/password + invite
- `POST /api/auth/login` - Login with email/password
- `GET /api/auth/google` - Start Google OAuth flow
- `GET /api/auth/google/callback` - Google OAuth callback
- `GET /api/auth/me` - Get current user (requires JWT)
- `POST /api/auth/logout` - Logout and revoke session

## 🎨 Brand Colors
- Primary Orange: `#FDAA25`
- Secondary Violet: `#CE7AFF`

## 🛡️ Security Features
- Rate limiting on all endpoints
- JWT with session revocation
- bcrypt password hashing
- Helmet security headers
- CORS protection
- Input validation with Zod

## 📊 Database Schema

### User
- `id` - Unique identifier
- `email` - Unique email address
- `username` - Unique username
- `passwordHash` - bcrypt hash (null for Google-only users)
- `googleId` - Google OAuth ID (optional)

### Invite
- `code` - 6-character alphanumeric code
- `createdBy` - Creator identifier
- `maxUses` - Maximum number of uses
- `usedCount` - Current usage count
- `expiresAt` - Optional expiration date
- `isActive` - Active status

### Session
- `id` - Session identifier
- `userId` - Associated user
- `jwtId` - JWT identifier for revocation
- `revokedAt` - Revocation timestamp (optional)

## 🚀 Deployment

### Vercel (Recommended)
1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push

### Environment Variables for Production
```
DATABASE_URL=postgresql://...
JWT_SECRET=your-secure-32-char-secret
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_CALLBACK_URL=https://your-domain.com/api/auth/google/callback
SESSION_SECRET=your-session-secret
NODE_ENV=production
```

## 🔧 Development Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run db:generate` - Generate Prisma client
- `npm run db:push` - Push schema to database
- `npm run db:migrate` - Run database migrations
- `npm run db:studio` - Open Prisma Studio

## 📝 Usage Flow

1. **Admin creates invite codes** using the script
2. **User receives invite code** from a friend
3. **User visits signup page** and enters invite code
4. **System verifies invite** and shows remaining uses
5. **User completes signup** with email/password or Google
6. **Invite usage is consumed** atomically
7. **User receives JWT token** for authenticated requests

## 🎯 Business Rules

- Invite codes are exactly 6 characters (A-Z, 0-9)
- Valid invites must be active, not expired, and have remaining uses
- Invite consumption happens in database transactions for consistency
- Google OAuth users still need valid invite codes for first signup
- JWT tokens expire after 7 days
- Sessions can be revoked for security

## 🔒 Security Considerations

- All passwords require minimum 8 characters with character type diversity
- Rate limiting prevents brute force attacks
- JWTs include revocation via session tracking
- HTTPS enforced in production
- Input validation on all endpoints
- SQL injection prevention via Prisma ORM

## 🎨 Frontend Features

- Responsive design with Tailwind CSS
- Real-time invite verification
- Animated particle background
- Form validation and error handling
- Google OAuth integration
- Modern glassmorphism UI design

---

Built with ❤️ for authentic connections through friends.
