// backend/utils/fcm.js
const admin = require('firebase-admin');
const User = require('../models/user.model');

// Initialize Firebase Admin SDK if not already initialized
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.applicationDefault(),
    });
}

/**
 * Send a push notification to a user by userId
 * @param {String} userId - The user's MongoDB ID
 * @param {Object} notification - { title, body, data }
 * @returns {Promise<Object>} FCM response
 */
async function sendPushToUser(userId, notification) {
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
    return admin.messaging().send(message);
}

module.exports = { sendPushToUser };
