// IndexedDB service for offline queue
const DB_NAME = "SafeStrideDB";
const DB_VERSION = 1;
const STORE_NAME = "offlineQueue";

class OfflineQueueService {
  constructor() {
    this.db = null;
  }

  async init() {
    if (this.db) return this.db;
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onerror = () => {
        console.error("❌ IndexedDB error:", request.error);
        reject(request.error);
      };

      request.onsuccess = () => {
        this.db = request.result;
        console.log("✅ IndexedDB initialized");
        resolve(this.db);
      };

      request.onupgradeneeded = (event) => {
        const db = event.target.result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          const store = db.createObjectStore(STORE_NAME, {
            keyPath: "id",
            autoIncrement: true,
          });
          store.createIndex("timestamp", "timestamp", { unique: false });
          store.createIndex("synced", "synced", { unique: false });
          store.createIndex("table", "table", { unique: false });
          console.log("📦 Offline queue store created");
        }
      };
    });
  }

  async addToQueue(action, table, data) {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readwrite");
      const store = transaction.objectStore(STORE_NAME);
      const item = {
        action,
        table,
        data,
        timestamp: Date.now(),
        synced: false,
        retries: 0,
      };
      const request = store.add(item);
      request.onsuccess = () => {
        console.log("✅ Added to offline queue:", item);
        // Try to register a background sync if available
        try {
          if ("serviceWorker" in navigator && "SyncManager" in window) {
            navigator.serviceWorker.ready.then((reg) => {
              reg.sync
                .register("sync-workouts")
                .then(() => {
                  console.log("🔁 Background sync registered");
                })
                .catch((err) => {
                  console.warn("⚠️ Background sync register failed:", err);
                });
            });
          }
        } catch (e) {
          console.warn(
            "Background sync not supported or failed to register",
            e,
          );
        }

        resolve(request.result);
      };
      request.onerror = () => {
        console.error("❌ Error adding to queue:", request.error);
        reject(request.error);
      };
    });
  }

  async getUnsyncedItems() {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readonly");
      const store = transaction.objectStore(STORE_NAME);
      const index = store.index("synced");
      const request = index.getAll(false);
      request.onsuccess = () => {
        console.log(`📋 Found ${request.result.length} unsynced items`);
        resolve(request.result);
      };
      request.onerror = () => {
        console.error("❌ Error getting unsynced items:", request.error);
        reject(request.error);
      };
    });
  }

  async markAsSynced(id) {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readwrite");
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get(id);
      request.onsuccess = () => {
        const item = request.result;
        if (item) {
          item.synced = true;
          item.syncedAt = Date.now();
          const updateRequest = store.put(item);
          updateRequest.onsuccess = () => {
            console.log("✅ Marked as synced:", id);
            resolve();
          };
          updateRequest.onerror = () => reject(updateRequest.error);
        } else {
          resolve();
        }
      };
      request.onerror = () => reject(request.error);
    });
  }

  async deleteSyncedItem(id) {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readwrite");
      const store = transaction.objectStore(STORE_NAME);
      const request = store.delete(id);
      request.onsuccess = () => {
        console.log("✅ Deleted synced item:", id);
        resolve();
      };
      request.onerror = () => {
        console.error("❌ Error deleting item:", request.error);
        reject(request.error);
      };
    });
  }

  async incrementRetries(id) {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readwrite");
      const store = transaction.objectStore(STORE_NAME);
      const request = store.get(id);
      request.onsuccess = () => {
        const item = request.result;
        if (item) {
          item.retries = (item.retries || 0) + 1;
          item.lastRetry = Date.now();
          const updateRequest = store.put(item);
          updateRequest.onsuccess = () => resolve(item.retries);
          updateRequest.onerror = () => reject(updateRequest.error);
        } else {
          resolve(0);
        }
      };
      request.onerror = () => reject(request.error);
    });
  }

  async getStats() {
    if (!this.db) await this.init();
    return new Promise((resolve, reject) => {
      const transaction = this.db.transaction([STORE_NAME], "readonly");
      const store = transaction.objectStore(STORE_NAME);
      const request = store.getAll();
      request.onsuccess = () => {
        const items = request.result || [];
        const stats = {
          total: items.length,
          unsynced: items.filter((i) => !i.synced).length,
          synced: items.filter((i) => i.synced).length,
          failed: items.filter((i) => i.retries >= 3).length,
        };
        resolve(stats);
      };
      request.onerror = () => reject(request.error);
    });
  }

  async clearSyncedItems() {
    if (!this.db) await this.init();
    const transaction = this.db.transaction([STORE_NAME], "readwrite");
    const store = transaction.objectStore(STORE_NAME);
    const req = store.openCursor();
    req.onsuccess = (e) => {
      const cursor = e.target.result;
      if (cursor) {
        const item = cursor.value;
        if (item.synced) cursor.delete();
        cursor.continue();
      }
    };
    req.onerror = (e) =>
      console.error("Error clearing synced items", e.target.error);
  }
}

const offlineQueue = new OfflineQueueService();
export default offlineQueue;
