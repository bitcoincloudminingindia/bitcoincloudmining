// Firebase messaging service worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyBTBr5z9vixdO9TzzKVGCUVP-G4BaaMAyo",
    authDomain: "bitcoin-cloud-mining-19fb5.firebaseapp.com",
    projectId: "bitcoin-cloud-mining-19fb5",
    storageBucket: "bitcoin-cloud-mining-19fb5.firebasestorage.app",
    messagingSenderId: "486206486627",
    appId: "1:486206486627:web:993fedd92937142473e056",
    measurementId: "G-LPLPZBE2YV"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase Cloud Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification?.title || 'New Message';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: payload.data
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
}); 