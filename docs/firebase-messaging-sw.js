importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

// Initialize Firebase with your configuration
firebase.initializeApp({
  apiKey: "AIzaSyDudk0G-cvMu10HEy2o7Brt7cDI8XvmjTU",
  authDomain: "surfspot-884c9.firebaseapp.com",
  projectId: "surfspot-884c9",
  storageBucket: "surfspot-884c9.firebasestorage.app",
  messagingSenderId: "37223953098",
  appId: "1:37223953098:web:d55cb317ac62d043113a33",
  vapidKey: 'BFgj1qFNfDDHSMrdh0-yoiAp2QQc8pQQb-g0yakvA2olKfmpQ5vC629WZ1YFFOISsIvqvXuf1IeuqhHFyOqclP0'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log("🌊 Received background push notification:", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});
