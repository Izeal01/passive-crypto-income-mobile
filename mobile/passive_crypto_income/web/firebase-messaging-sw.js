importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Extracted from your lib/firebase_options.dart (web section) - UPDATE THESE VALUES!
static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCkTw6wNHC0F9IrQAeYJWmdCZgugS6P_sU',
    appId: '1:1021456818171:web:5310ed0b8271288f9d755e',
    messagingSenderId: '1021456818171',
    projectId: 'passive-crypto-c3e0b',
    authDomain: 'passive-crypto-c3e0b.firebaseapp.com',
    storageBucket: 'passive-crypto-c3e0b.firebasestorage.app',
    measurementId: 'G-TX4PYXFWR9',
  );

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background message received:', payload);
  const notificationTitle = payload.notification?.title || 'Arbitrage Alert!';
  const notificationOptions = {
    body: payload.notification?.body || `Profitable XRP/USDT trade executed: ${payload.data?.pnl ?? 'Check app'}% PnL`,
    icon: '/icons/Icon-192.png'  // Use your app icon if added
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});
