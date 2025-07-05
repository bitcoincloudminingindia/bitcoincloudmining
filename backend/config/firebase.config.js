const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
    try {
        // Option 1: Using service account key file (recommended for production)
        const serviceAccountPath = path.join(__dirname, '../bitcoin-cloud-mining-19fb5-firebase-adminsdk-fbsvc-42a7642109.json');

        if (require('fs').existsSync(serviceAccountPath)) {
            const serviceAccount = require(serviceAccountPath);
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                databaseURL: process.env.FIREBASE_DATABASE_URL || 'https://bitcoin-cloud-mining-19fb5.firebaseio.com'
            });
        } else {
            // Option 2: Using environment variables (for development)
            admin.initializeApp({
                credential: admin.credential.cert({
                    type: process.env.FIREBASE_TYPE,
                    project_id: process.env.FIREBASE_PROJECT_ID,
                    private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
                    private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                    client_email: process.env.FIREBASE_CLIENT_EMAIL,
                    client_id: process.env.FIREBASE_CLIENT_ID,
                    auth_uri: process.env.FIREBASE_AUTH_URI,
                    token_uri: process.env.FIREBASE_TOKEN_URI,
                    auth_provider_x509_cert_url: process.env.FIREBASE_AUTH_PROVIDER_X509_CERT_URL,
                    client_x509_cert_url: process.env.FIREBASE_CLIENT_X509_CERT_URL
                }),
                databaseURL: process.env.FIREBASE_DATABASE_URL
            });
        }

        console.log('✅ Firebase Admin SDK initialized successfully');
        return admin;
    } catch (error) {
        console.error('❌ Firebase Admin SDK initialization failed:', error);
        throw error;
    }
};

// Verify Firebase ID token
const verifyIdToken = async (idToken) => {
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        return {
            success: true,
            data: decodedToken
        };
    } catch (error) {
        console.error('Firebase token verification failed:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

// Get user by Firebase UID
const getUserByUid = async (uid) => {
    try {
        const userRecord = await admin.auth().getUser(uid);
        return {
            success: true,
            data: userRecord
        };
    } catch (error) {
        console.error('Firebase user fetch failed:', error);
        return {
            success: false,
            error: error.message
        };
    }
};

module.exports = {
    admin,
    initializeFirebase,
    verifyIdToken,
    getUserByUid
}; 