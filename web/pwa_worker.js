// 'use strict';

// const CACHE_NAME = 'tdr-v2.5'; 

// // ✅ Improved for Android: Explicitly include "/" to match your manifest start_url
// const CORE_ASSETS = [
//   '/', 
//   'index.html',
//   'main.dart.js',
//   'flutter_bootstrap.js',
//   'manifest.json',
//   'assets/AssetManifest.json'
// ];

// self.addEventListener("install", (event) => {
//   self.skipWaiting();
//   event.waitUntil(
//     caches.open(CACHE_NAME).then((cache) => {
//       // We use a map to catch errors if one file fails to load
//       return Promise.all(
//         CORE_ASSETS.map(url => {
//           return cache.add(url).catch(err => console.warn(`Failed to cache: ${url}`, err));
//         })
//       );
//     })
//   );
// });

// self.addEventListener("activate", (event) => {
//   event.waitUntil(
//     caches.keys().then((keys) => Promise.all(
//       keys.map((key) => { 
//         if (key !== CACHE_NAME) return caches.delete(key); 
//       })
//     )).then(() => self.clients.claim())
//   );
// });

// self.addEventListener("fetch", (event) => {
//   // ✅ Android requirement: The fetch handler must exist and respond to the start_url
//   event.respondWith(
//     caches.match(event.request).then((res) => {
//       return res || fetch(event.request).catch(() => {
//         // Optional: Return a custom offline page here if the network fails
//       });
//     })
//   );
// });