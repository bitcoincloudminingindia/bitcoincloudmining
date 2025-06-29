// backend/utils/fcm.js
const admin = require('firebase-admin');
const User = require('../models/user.model');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
    try {
        // Try to use service account key from environment
        const serviceAccount = {
            type: process.env.FIREBASE_TYPE || "service_account",
            project_id: process.env.FIREBASE_PROJECT_ID || "bitcoin-cloud-mining-19fb5",
            private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
            private_key: process.env.FIREBASE_PRIVATE_KEY ? 
                process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n') : undefined,
            client_email: process.env.FIREBASE_CLIENT_EMAIL,
            client_id: process.env.FIREBASE_CLIENT_ID,
            auth_uri: process.env.FIREBASE_AUTH_URI || "https://accounts.google.com/o/oauth2/auth",
            token_uri: process.env.FIREBASE_TOKEN_URI || "https://oauth2.googleapis.com/token",
            auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL || 
                "https://www.googleapis.com/oauth2/v1/certs",
            client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
        };

        // Check if we have the required credentials
        if (serviceAccount.private_key && serviceAccount.client_email) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            console.log('✅ Firebase Admin SDK initialized with service account');
        } else {
            // Fallback to application default credentials
            admin.initializeApp({
                credential: admin.credential.applicationDefault(),
            });
            console.log('✅ Firebase Admin SDK initialized with application default credentials');
        }
    } catch (error) {
        console.error('❌ Firebase Admin SDK initialization failed:', error);
        // Initialize without credentials for now
        admin.initializeApp();
        console.log('⚠️ Firebase Admin SDK initialized without credentials');
    }
}

/**
 * Send a push notification to a user by userId
 * @param {String} userId - The user's MongoDB ID
 * @param {Object} notification - { title, body, data }
 * @returns {Promise<Object>} FCM response
 */
async function sendPushToUser(userId, notification) {
    try {
        const user = await User.findById(userId);
        if (!user || !user.fcmToken) {
            throw new Error('User or FCM token not found');
        }
        
        const message = {
            token: user.fcmToken,
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data || {},
        };
        
        const response = await admin.messaging().send(message);
        console.log('✅ Push notification sent successfully:', response);
        return response;
    } catch (error) {
        console.error('❌ Failed to send push notification:', error);
        throw error;
    }
}

module.exports = { sendPushToUser };
