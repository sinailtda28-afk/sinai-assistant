// Service Worker for Assistente de Produtividade
self.addEventListener("install", (e) => {
  e.waitUntil(self.skipWaiting());
});

self.addEventListener("activate", (e) => {
  e.waitUntil(self.clients.claim());
});

// Push notifications (will be implemented in Phase 5)
self.addEventListener("push", (e) => {
  // const data = e.data.json();
  // self.registration.showNotification(data.title, {
  //   body: data.body,
  //   icon: "/icon-192.png"
  // });
});
