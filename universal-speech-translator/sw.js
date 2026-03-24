const CACHE_NAME = 'translator-v1';
const ASSETS_TO_CACHE = [
    './',
    './index.html',
    './styles.css',
    './app.js',
    './manifest.json',
    './icons/icon-192.png',
    './icons/icon-512.png'
];

// Install: cache app shell
self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            return cache.addAll(ASSETS_TO_CACHE);
        })
    );
    self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) => {
            return Promise.all(
                keys.filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            );
        })
    );
    self.clients.claim();
});

// Fetch: network-first for API calls, cache-first for app shell
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);

    // Always go to network for translation API
    if (url.hostname === 'api.mymemory.translated.net') {
        event.respondWith(
            fetch(event.request).catch(() => {
                return new Response(JSON.stringify({
                    responseStatus: 500,
                    responseData: { translatedText: 'Offline — translation unavailable' }
                }), { headers: { 'Content-Type': 'application/json' } });
            })
        );
        return;
    }

    // Cache-first for app assets
    event.respondWith(
        caches.match(event.request).then((cached) => {
            return cached || fetch(event.request).then((response) => {
                // Cache new assets dynamically
                if (response.ok) {
                    const clone = response.clone();
                    caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
                }
                return response;
            });
        })
    );
});
