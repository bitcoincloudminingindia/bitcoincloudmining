const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const adminAuth = require('../middleware/adminAuth');
const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const Transaction = require('../models/transaction.model');
const SocialMedia = require('../models/social_media.model');
const logger = require('../utils/logger');

// Get all social media platforms (public)
router.get('/platforms', async (req, res) => {
  try {
    const platforms = await SocialMedia.find({ isActive: true })
      .select('platform handle url rewardAmount')
      .lean();

    res.json({
      success: true,
      data: platforms
    });
  } catch (error) {
    logger.error('Get social media platforms error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching social media platforms'
    });
  }
});

// Admin routes
// Add new social media platform
router.post('/admin/platform', adminAuth, async (req, res) => {
  try {
    const { platform, handle, url, rewardAmount, verificationMethod, apiCredentials, webhookUrl } = req.body;

    const socialMedia = new SocialMedia({
      platform,
      handle,
      url,
      rewardAmount,
      verificationMethod,
      apiCredentials,
      webhookUrl
    });

    await socialMedia.save();

    res.status(201).json({
      success: true,
      message: 'Social media platform added successfully',
      data: socialMedia
    });
  } catch (error) {
    logger.error('Add social media platform error:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding social media platform'
    });
  }
});

// Update social media platform
router.put('/admin/platform/:platform', adminAuth, async (req, res) => {
  try {
    const { platform } = req.params;
    const updateData = req.body;

    const socialMedia = await SocialMedia.findOneAndUpdate(
      { platform },
      { $set: updateData },
      { new: true }
    );

    if (!socialMedia) {
      return res.status(404).json({
        success: false,
        message: 'Social media platform not found'
      });
    }

    res.json({
      success: true,
      message: 'Social media platform updated successfully',
      data: socialMedia
    });
  } catch (error) {
    logger.error('Update social media platform error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating social media platform'
    });
  }
});

// Delete social media platform
router.delete('/admin/platform/:platform', adminAuth, async (req, res) => {
  try {
    const { platform } = req.params;

    const socialMedia = await SocialMedia.findOneAndDelete({ platform });

    if (!socialMedia) {
      return res.status(404).json({
        success: false,
        message: 'Social media platform not found'
      });
    }

    res.json({
      success: true,
      message: 'Social media platform deleted successfully'
    });
  } catch (error) {
    logger.error('Delete social media platform error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting social media platform'
    });
  }
});

// Verify social media follow/subscribe (updated to use SocialMedia model)
router.post('/verify-social-media', auth, async (req, res) => {
  try {
    const { platform, actionType, timestamp } = req.body;
    const userId = req.user.userId || req.user.id;

    // Get platform details
    const platformDetails = await SocialMedia.findOne({ 
      platform,
      isActive: true 
    });

    if (!platformDetails) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive platform'
      });
    }

    // Validate action type
    const validActions = ['follow', 'subscribe'];
    if (!validActions.includes(actionType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action type'
      });
    }

    // Get user's social media verification status
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if user has already verified this platform
    if (user.socialMediaVerified?.[platform]) {
      return res.status(400).json({
        success: false,
        message: `Already verified ${platform} ${actionType}`
      });
    }

    // Verify based on platform's verification method
    let isVerified = false;
    switch (platformDetails.verificationMethod) {
      case 'api':
        // Implement API verification
        isVerified = await verifyWithApi(platform, userId, platformDetails.apiCredentials);
        break;
      case 'webhook':
        // Implement webhook verification
        isVerified = await verifyWithWebhook(platform, userId, platformDetails.webhookUrl);
        break;
      case 'manual':
        // For manual verification, admin needs to approve
        isVerified = false;
        // Create verification request for admin
        await createVerificationRequest(userId, platform, actionType);
        break;
    }

    if (isVerified) {
      // Update user's social media verification status
      if (!user.socialMediaVerified) {
        user.socialMediaVerified = {};
      }
      user.socialMediaVerified[platform] = true;
      await user.save();

      // Create transaction for social media reward
      const transaction = new Transaction({
        userId: user._id,
        amount: platformDetails.rewardAmount,
        type: 'social_reward',
        status: 'pending',
        description: `${platform.charAt(0).toUpperCase() + platform.slice(1)} ${actionType} reward`,
        metadata: {
          platform,
          actionType,
          timestamp
        }
      });
      await transaction.save();

      // Update platform's last verified timestamp
      platformDetails.lastVerified = new Date();
      await platformDetails.save();
    }

    res.json({
      success: true,
      message: isVerified ? 
        `${platform} ${actionType} verified successfully` : 
        'Verification request submitted for admin approval',
      data: {
        verified: isVerified,
        rewardAmount: isVerified ? platformDetails.rewardAmount : '0.000000000000000000'
      }
    });

  } catch (error) {
    logger.error('Social media verification error:', error);
    res.status(500).json({
      success: false,
      message: 'Error verifying social media action'
    });
  }
});

// Helper functions for verification
async function verifyWithApi(platform, userId, credentials) {
  // Implement API verification logic here
  // This would use the platform's API to check follow/subscribe status
  return false; // Placeholder
}

async function verifyWithWebhook(platform, userId, webhookUrl) {
  // Implement webhook verification logic here
  // This would wait for a webhook callback from the platform
  return false; // Placeholder
}

async function createVerificationRequest(userId, platform, actionType) {
  // Create a verification request for admin approval
  // This could be stored in a separate collection
  // For now, we'll just log it
  logger.info(`Verification request created for user ${userId} on ${platform} ${actionType}`);
}

module.exports = router; 