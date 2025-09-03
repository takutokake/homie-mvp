import { prisma } from '../api/lib/prisma.js';

function generateInviteCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

async function createInvite(options: {
  maxUses?: number;
  expiresAt?: Date | null;
  createdBy?: string;
}) {
  const { maxUses = 1, expiresAt = null, createdBy = 'admin@homie' } = options;
  
  let code: string;
  let attempts = 0;
  const maxAttempts = 10;

  // Generate unique code
  do {
    code = generateInviteCode();
    attempts++;
    
    if (attempts > maxAttempts) {
      throw new Error('Failed to generate unique invite code after multiple attempts');
    }
    
    const existing = await prisma.invite.findUnique({ where: { code } });
    if (!existing) break;
  } while (true);

  const invite = await prisma.invite.create({
    data: {
      code,
      createdBy,
      maxUses,
      expiresAt,
    }
  });

  console.log(`✅ Created invite: ${invite.code}`);
  console.log(`   Max uses: ${invite.maxUses}`);
  console.log(`   Expires: ${invite.expiresAt || 'Never'}`);
  console.log(`   Created by: ${invite.createdBy}`);
  
  return invite;
}

// CLI usage
async function main() {
  const args = process.argv.slice(2);
  
  let maxUses = 1;
  let expiresAt: Date | null = null;
  let createdBy = 'admin@homie';
  
  // Parse command line arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    
    if (arg === '--max-uses' && args[i + 1]) {
      maxUses = parseInt(args[i + 1]);
      i++; // Skip next argument
    } else if (arg === '--expires' && args[i + 1]) {
      expiresAt = new Date(args[i + 1]);
      i++; // Skip next argument
    } else if (arg === '--created-by' && args[i + 1]) {
      createdBy = args[i + 1];
      i++; // Skip next argument
    } else if (arg === '--help') {
      console.log(`
Usage: npm run create-invite [options]

Options:
  --max-uses <number>     Maximum number of uses (default: 1)
  --expires <date>        Expiration date in ISO format (default: never)
  --created-by <string>   Creator identifier (default: admin@homie)
  --help                  Show this help message

Examples:
  npm run create-invite
  npm run create-invite -- --max-uses 5
  npm run create-invite -- --max-uses 3 --expires "2024-12-31T23:59:59Z"
  npm run create-invite -- --max-uses 10 --created-by "takuto@homie"
      `);
      process.exit(0);
    }
  }
  
  try {
    await createInvite({ maxUses, expiresAt, createdBy });
  } catch (error) {
    console.error('❌ Error creating invite:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { createInvite, generateInviteCode };
