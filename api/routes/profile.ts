import { Router } from 'express';
import { prisma } from '../lib/prisma';
import { supabaseAdmin } from '../lib/supabase';
import { authenticateToken, AuthenticatedRequest } from '../middleware/auth';
import { Response } from 'express';

const router = Router();

router.post('/complete-profile', authenticateToken, async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.userId) {
      return res.status(401).json({ error: 'User not authenticated' });
    }

    const {
      displayName,
      phoneNumber,
      school,
      locationDetails,
      priceRange,
      meetingPreference,
      interests,
      cuisinePreferences
    } = req.body;

    // Validate required fields
    if (!displayName || !school || !priceRange) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Update user profile in database
    const updatedUser = await prisma.user.update({
      where: { id: req.userId },
      data: {
        displayName,
        phoneNumber,
        school,
        locationDetails,
        priceRange,
        meetingPreference,
        interests,
        cuisinePreferences,
        profileCompleted: true,
        updatedAt: new Date()
      }
    });

    return res.json({ success: true, user: updatedUser });
  } catch (error) {
    console.error('Profile completion error:', error);
    return res.status(500).json({ error: 'Failed to complete profile' });
  }
});

export default router;
