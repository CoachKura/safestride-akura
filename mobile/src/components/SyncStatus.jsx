import { useState, useEffect } from "react";
import syncService from "../services/syncService";
import offlineQueue from "../services/offlineQueue";

export default function SyncStatus() {
  const [syncStatus, setSyncStatus] = useState({ status: "idle" });
  const [queueStats, setQueueStats] = useState({ total: 0, unsynced: 0 });
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const unsubscribe = syncService.onSyncStatusChange(setSyncStatus);

    updateQueueStats();
    const statsInterval = setInterval(updateQueueStats, 5000);

    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      unsubscribe();
      clearInterval(statsInterval);
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  async function updateQueueStats() {
    const stats = await offlineQueue.getStats();
    setQueueStats(stats);
  }

  function handleManualSync() {
    syncService.syncAll();
  }

  if (queueStats.unsynced === 0 && isOnline && syncStatus.status === "idle") {
    return null;
  }

  return (
    <div className="fixed top-0 left-0 right-0 z-50 safe-area-inset-top">
      {!isOnline && (
        <div className="bg-orange-500 text-white px-4 py-2 flex items-center justify-center gap-2 text-sm font-medium">
          <div className="w-2 h-2 bg-white rounded-full"></div>
          <span>You're offline - changes will sync when reconnected</span>
        </div>
      )}

      {syncStatus.status === "syncing" && (
        <div className="bg-primary text-white px-4 py-2">
          <div className="flex items-center justify-between mb-1">
            <span className="text-sm font-medium">
              Syncing {syncStatus.current || 0}/{syncStatus.total || 0}...
            </span>
            <span className="text-sm">{syncStatus.progress || 0}%</span>
          </div>
          <div className="w-full bg-white bg-opacity-30 rounded-full h-1.5 overflow-hidden">
            <div
              className="bg-white h-full transition-all duration-300"
              style={{ width: `${syncStatus.progress || 0}%` }}
            />
          </div>
        </div>
      )}

      {syncStatus.status === "complete" && (
        <div className="bg-green-500 text-white px-4 py-2 flex items-center justify-center gap-2 text-sm font-medium">
          <span>✅</span>
          <span>
            Synced {syncStatus.success || 0} items
            {syncStatus.failed > 0 && ` (${syncStatus.failed} failed)`}
          </span>
        </div>
      )}

      {isOnline && queueStats.unsynced > 0 && syncStatus.status === "idle" && (
        <div className="bg-yellow-500 text-white px-4 py-2 flex items-center justify-between">
          <span className="text-sm font-medium">
            {queueStats.unsynced} items waiting to sync
          </span>
          <button
            onClick={handleManualSync}
            className="bg-white text-yellow-600 px-3 py-1 rounded-full text-sm font-semibold hover:bg-opacity-90 transition"
          >
            Sync Now
          </button>
        </div>
      )}
    </div>
  );
}
