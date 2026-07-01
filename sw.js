/* Panigiria Serifou — Service Worker
 * - Offline app-shell caching
 * - Local reminder notifications a few days before each festival
 * - Background firing via Periodic Background Sync (where supported)
 * - Server push support (no-op until a backend is added)
 */
const VERSION = 'panigiria-v2';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-maskable-512.png',
  './icons/apple-touch-icon.png',
  './icons/favicon-32.png',
];

/* ---------- install / activate ---------- */
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(VERSION)
      .then((c) => c.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
      .catch(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== VERSION).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

/* ---------- fetch: cache-first for app shell, network otherwise ---------- */
self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Only handle same-origin (Google Fonts etc. go straight to network).
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    caches.match(req).then((cached) => {
      if (cached) return cached;
      return fetch(req)
        .then((res) => {
          const copy = res.clone();
          caches.open(VERSION).then((c) => c.put(req, copy)).catch(() => {});
          return res;
        })
        .catch(() => caches.match('./index.html'));
    })
  );
});

/* ---------- tiny IndexedDB helpers (SW can't use localStorage) ---------- */
function idb() {
  return new Promise((resolve, reject) => {
    const open = indexedDB.open('panigiria', 1);
    open.onupgradeneeded = () => {
      const db = open.result;
      if (!db.objectStoreNames.contains('kv')) db.createObjectStore('kv');
    };
    open.onsuccess = () => resolve(open.result);
    open.onerror = () => reject(open.error);
  });
}
async function idbGet(key) {
  const db = await idb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction('kv', 'readonly').objectStore('kv').get(key);
    tx.onsuccess = () => resolve(tx.result);
    tx.onerror = () => reject(tx.error);
  });
}
async function idbSet(key, val) {
  const db = await idb();
  return new Promise((resolve, reject) => {
    const tx = db.transaction('kv', 'readwrite');
    tx.objectStore('kv').put(val, key);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
}

/* ---------- reminder logic ---------- */
// A schedule entry: { id, title, body, fireTs, eventTs }
// "due" = fire time reached, event not yet passed, and not already fired.
async function checkReminders() {
  const schedule = (await idbGet('schedule')) || [];
  const fired = (await idbGet('fired')) || {};
  const now = Date.now();
  let changed = false;

  for (const r of schedule) {
    if (fired[r.id]) continue;
    if (now >= r.fireTs && now <= r.eventTs + 86400000) {
      await self.registration.showNotification(r.title, {
        body: r.body,
        tag: r.id,
        icon: './icons/icon-192.png',
        badge: './icons/favicon-32.png',
        lang: 'el',
        requireInteraction: false,
        data: { url: './index.html', eventId: r.eventId || null },
      });
      fired[r.id] = now;
      changed = true;
    }
  }
  if (changed) await idbSet('fired', fired);
}

self.addEventListener('message', (event) => {
  const msg = event.data || {};
  if (msg.type === 'SET_SCHEDULE') {
    event.waitUntil(idbSet('schedule', msg.schedule || []).then(checkReminders));
  } else if (msg.type === 'CHECK_REMINDERS') {
    event.waitUntil(checkReminders());
  } else if (msg.type === 'TEST_NOTIFICATION') {
    event.waitUntil(
      self.registration.showNotification(msg.title || 'Πανηγύρια Σερίφου', {
        body: msg.body || 'Οι ειδοποιήσεις λειτουργούν! 🎻',
        icon: './icons/icon-192.png',
        badge: './icons/favicon-32.png',
        tag: 'panigiria-test',
        data: { url: './index.html' },
      })
    );
  }
});

/* Periodic Background Sync — fires while the app is closed (Chromium/Android). */
self.addEventListener('periodicsync', (event) => {
  if (event.tag === 'panigiria-reminders') event.waitUntil(checkReminders());
});

/* One-off background sync fallback (fires when connectivity returns). */
self.addEventListener('sync', (event) => {
  if (event.tag === 'panigiria-reminders') event.waitUntil(checkReminders());
});

/* Server push — used only if a backend is added later. */
self.addEventListener('push', (event) => {
  let data = {};
  try { data = event.data ? event.data.json() : {}; } catch (e) { data = { body: event.data && event.data.text() }; }
  event.waitUntil(
    self.registration.showNotification(data.title || 'Πανηγύρια Σερίφου', {
      body: data.body || '',
      icon: './icons/icon-192.png',
      badge: './icons/favicon-32.png',
      data: { url: data.url || './index.html' },
    })
  );
});

/* Tapping a notification focuses (or opens) the app. */
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = (event.notification.data && event.notification.data.url) || './index.html';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const c of clients) {
        if ('focus' in c) { c.focus(); return; }
      }
      if (self.clients.openWindow) return self.clients.openWindow(target);
    })
  );
});
