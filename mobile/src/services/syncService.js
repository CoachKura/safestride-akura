import offlineQueue from "./offlineQueue";
import { supabase } from "./supabase";

class SyncService {
  constructor({ intervalMs = 30000 } = {}) {
    this.intervalMs = intervalMs;
    this.listeners = new Set();
    this.syncing = false;
    this._timer = null;

    this._onOnline = this._onOnline.bind(this);
    this._onVisibility = this._onVisibility.bind(this);

    if (typeof window !== "undefined") {
      window.addEventListener("online", this._onOnline);
      document.addEventListener("visibilitychange", this._onVisibility);
    }

    this.startAutoInterval();
  }

  onSyncStatusChange(cb) {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  _emit(event, payload = {}) {
    const message = { event, ...payload };
    for (const cb of this.listeners) cb(message);
  }

  startAutoInterval() {
    if (this._timer) return;
    this._timer = setInterval(() => {
      if (navigator.onLine) this.syncAll().catch(() => {});
    }, this.intervalMs);
  }

  stopAutoInterval() {
    if (!this._timer) return;
    clearInterval(this._timer);
    this._timer = null;
  }

  _onOnline() {
    this._emit("online");
    setTimeout(() => this.syncAll().catch(() => {}), 1000);
  }

  _onVisibility() {
    if (document.visibilityState === "visible") {
      setTimeout(() => this.syncAll().catch(() => {}), 500);
    }
  }

  async syncAll() {
    if (this.syncing) return;
    if (!navigator.onLine) return;

    this.syncing = true;
    this._emit("sync:start");

    try {
      const items = await offlineQueue.getUnsyncedItems();
      this._emit("sync:items", { total: items.length });

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        try {
          await this._syncItem(item);
          await offlineQueue.markAsSynced(item.id);
          // schedule removal later (cleanup)
          setTimeout(() => offlineQueue.deleteSyncedItem(item.id).catch(() => {}), 24 * 60 * 60 * 1000);
          this._emit("sync:item:done", { item });
        } catch (err) {
          await offlineQueue.incrementRetries(item.id).catch(() => {});
          this._emit("sync:item:error", { item, error: err });
        }
        this._emit("sync:progress", { current: i + 1, total: items.length });
      }

      this._emit("sync:complete", { count: items.length });
    } catch (err) {
      this._emit("sync:error", { error: err });
    } finally {
      this.syncing = false;
      this._emit("sync:finished");
    }
  }

  async _syncItem(item) {
    const { action, table, data } = item;

    if (!table || !action) throw new Error("Invalid queue item: missing table or action");

    if (action === "insert") {
      const { error } = await supabase.from(table).insert(data);
      if (error) throw error;
    } else if (action === "update") {
      const id = data?.id;
      if (!id) throw new Error("Missing id for update");
      const { error } = await supabase.from(table).update(data).eq("id", id);
      if (error) throw error;
    } else if (action === "delete") {
      const id = data?.id;
      if (!id) throw new Error("Missing id for delete");
      const { error } = await supabase.from(table).delete().eq("id", id);
      if (error) throw error;
    } else {
      throw new Error(`Unknown action: ${action}`);
    }
  }

  dispose() {
    if (typeof window !== "undefined") {
      window.removeEventListener("online", this._onOnline);
      document.removeEventListener("visibilitychange", this._onVisibility);
    }
    this.stopAutoInterval();
    this.listeners.clear();
  }
}

const syncService = new SyncService();
export default syncService;
