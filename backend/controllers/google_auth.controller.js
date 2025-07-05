const { User, Wallet } = require('../models');
const { verifyIdToken } = require('../config/firebase.config');
const { generateToken } = require('../utils/auth');
const { generateReferralCode } = require('../utils/generators');
const logger = require('../utils/logger');
const crypto = require('crypto');

// Generate unique user ID
const generateUserId = () => {
    const timestamp = Date.now().toString();
    const random = crypto.randomBytes(2).toString('hex');
    return `USR${timestamp}${random}`;
};

// Google Sign-In authentication
exports.googleSignIn = async (req, res) => {
    try {
        const { firebaseUid, email, displayName, photoURL } = req.body;
        const idToken = req.headers.authorization?.split('Bearer ')[1];

        if (!idToken) {
            return res.status(401).json({
                success: false,
                message: 'Firebase ID token is required'
            });
        }

        // Step 1: Verify Firebase ID token
        const tokenVerification = await verifyIdToken(idToken);
        if (!tokenVerification.success) {
            return res.status(401).json({
                success: false,
                message: 'Invalid Firebase token'
            });
        }

        const decodedToken = tokenVerification.data;

        // Step 2: Verify UID matches
        if (decodedToken.uid !== firebaseUid) {
            return res.status(401).json({
                success: false,
                message: 'Token UID mismatch'
            });
        }

        // Step 3: Check if user already exists
        let user = await User.findOne({
            $or: [
                { firebaseUid: firebaseUid },
                { userEmail: email?.toLowerCase() }
            ]
        });

        if (user) {
            // Update existing user with latest Firebase info
            user.firebaseUid = firebaseUid;
            user.fullName = displayName || user.fullName;
            user.profilePicture = photoURL || user.profilePicture;
            user.lastLoginAt = new Date();
            user.loginHistory.push({
                timestamp: new Date(),
                ip: req.ip,
                userAgent: req.get('User-Agent')
            });

            await user.save();

            // Generate new token
            const token = generateToken({
                userId: user.userId,
                id: user._id,
                timestamp: new Date().toISOString()
            });

            return res.status(200).json({
                success: true,
                message: 'Google Sign-In successful',
                data: {
                    token,
                    user: {
                        userId: user.userId,
                        fullName: user.fullName,
                        userName: user.userName,
                        userEmail: user.userEmail,
                        profilePicture: user.profilePicture,
                        referralCode: user.referralCode,
                        isEmailVerified: true, // Google users are pre-verified
                        wallet: user.wallet
                    }
                }
            });
        }

        // Step 4: Create new user
        const userId = generateUserId();
        const userReferralCode = generateReferralCode();

        user = await User.create({
            userId,
            firebaseUid,
            fullName: displayName || 'Google User',
            userEmail: email?.toLowerCase(),
            userName: email?.split('@')[0]?.toLowerCase() || `user${Date.now()}`,
            profilePicture: photoURL,
            isEmailVerified: true, // Google users are pre-verified
            userReferralCode,
            status: 'active',
            lastLoginAt: new Date(),
            loginHistory: [{
                timestamp: new Date(),
                ip: req.ip,
                userAgent: req.get('User-Agent')
            }]
        });

        // Step 5: Create wallet for new user
        const wallet = new Wallet({
            user: user._id,
            userId: user.userId,
            walletId: 'WAL' + crypto.randomBytes(8).toString('hex').toUpperCase(),
            balance: '0.000000000000000000',
            currency: 'BTC',
            address: 'bc1' + crypto.randomBytes(20).toString('hex').slice(0, 40)
        });

        await wallet.save();

        // Step 6: Generate token
        const token = generateToken({
            userId: user.userId,
            id: user._id,
            timestamp: new Date().toISOString()
        });

        logger.info(`Google Sign-In successful for user: ${user.userId}`);

        res.status(201).json({
            success: true,
            message: 'Google Sign-In successful',
            data: {
                token,
                user: {
                    userId: user.userId,
                    fullName: user.fullName,
                    userName: user.userName,
                    userEmail: user.userEmail,
                    profilePicture: user.profilePicture,
                    referralCode: user.referralCode,
                    isEmailVerified: true,
                    wallet: user.wallet
                }
            }
        });

    } catch (error) {
        logger.error('Google Sign-In error:', error);
        res.status(500).json({
            success: false,
            message: 'Google Sign-In failed'
        });
    }
};

// Link existing account with Google
exports.linkGoogleAccount = async (req, res) => {
    try {
        const { firebaseUid, email } = req.body;
        const idToken = req.headers.authorization?.split('Bearer ')[1];
        const currentUser = req.user;

        if (!idToken) {
            return res.status(401).json({
                success: false,
                message: 'Firebase ID token is required'
            });
        }

        // Verify Firebase token
        const tokenVerification = await verifyIdToken(idToken);
        if (!tokenVerification.success) {
            return res.status(401).json({
                success: false,
                message: 'Invalid Firebase token'
            });
        }

        // Check if Google account is already linked to another user
        const existingGoogleUser = await User.findOne({ firebaseUid });
        if (existingGoogleUser && existingGoogleUser.userId !== currentUser.userId) {
            return res.status(400).json({
                success: false,
                message: 'This Google account is already linked to another user'
            });
        }

        // Link Google account to current user
        const user = await User.findById(currentUser.id);
        user.firebaseUid = firebaseUid;
        user.isEmailVerified = true; // Google verification
        await user.save();

        res.status(200).json({
            success: true,
            message: 'Google account linked successfully'
        });

    } catch (error) {
        logger.error('Link Google account error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to link Google account'
        });
    }
}; 