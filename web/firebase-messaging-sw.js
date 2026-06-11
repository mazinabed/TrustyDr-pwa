// Firebase Messaging Service Worker — background push handler for TrustyDr patient app.
// This file must remain at web/firebase-messaging-sw.js (root of the served web directory).
// The Flutter service worker (flutter_service_worker.js) coexists without conflict.

importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAyBhbQAQZboBJd90lSqJNZuBOVcEOGJ3E',
  appId: '1:423685278731:web:767c5e00bb075e532e8b0e',
  messagingSenderId: '423685278731',
  projectId: 'doctorapp-7e8b3',
  authDomain: 'doctorapp-7e8b3.firebaseapp.com',
  storageBucket: 'doctorapp-7e8b3.firebasestorage.app',
});

const messaging = firebase.messaging();

// Handle push notifications when the app is in the background or closed.
messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'TrustyDr';
  const body  = (payload.notification && payload.notification.body)  || '';
  const data  = payload.data || {};

  return self.registration.showNotification(title, {
    body:  body,
    icon:  '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data:  data,
    // Collapse duplicate reminders for the same appointment.
    tag:   data.appointmentId || 'trustydr-notification',
  });
});

// Tap a notification → open / focus the app and navigate to Notifications page.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const appUrl  = self.location.origin + '/';
  const destUrl = appUrl + '#notifications';

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        for (const client of windowClients) {
          if ('focus' in client) {
            client.postMessage({ type: 'NOTIFICATION_CLICK', data: event.notification.data });
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(destUrl);
        }
      }),
  );
});
