const CACHE_NAME = 'openmoi-pwa-v1.2.2';

// Core resources to pre-cache immediately upon installation
const PRECACHE_RESOURCES = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'sqlite3.wasm',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/AssetManifest.json',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png'
];

// Install event - pre-cache critical app shell & runtime assets
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_RESOURCES).catch((error) => {
        console.warn('PWA Pre-cache partial warning:', error);
      });
    })
  );
});

// Activate event - clean up legacy cache containers and take control immediately
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => cacheName !== CACHE_NAME)
          .map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - Cache-First strategy with background update & navigation fallback
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    caches.match(event.request, { ignoreSearch: false }).then((cachedResponse) => {
      if (cachedResponse) {
        // Return cached response immediately, update cache in background when online
        fetch(event.request)
          .then((networkResponse) => {
            if (networkResponse && (networkResponse.status === 200 || networkResponse.type === 'opaque')) {
              const responseToCache = networkResponse.clone();
              caches.open(CACHE_NAME).then((cache) => {
                cache.put(event.request, responseToCache);
              });
            }
          })
          .catch(() => {
            /* ignore network errors when offline */
          });
        return cachedResponse;
      }

      // If not in cache, fetch from network and store in cache (supports basic, cors, opaque)
      return fetch(event.request)
        .then((networkResponse) => {
          if (
            networkResponse &&
            (networkResponse.status === 200 || networkResponse.type === 'opaque')
          ) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseToCache);
            });
          }
          return networkResponse;
        })
        .catch((error) => {
          // Navigation fallback for offline HTML launch
          if (event.request.mode === 'navigate') {
            return (
              caches.match('index.html') ||
              caches.match('./') ||
              caches.match(location.origin + location.pathname)
            );
          }
          throw error;
        });
    })
  );
});
