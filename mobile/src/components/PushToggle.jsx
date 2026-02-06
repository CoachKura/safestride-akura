import { useState } from "react";
import pushService from "../services/pushService";

export default function PushToggle() {
  const [enabled, setEnabled] = useState(false);
  const [loading, setLoading] = useState(false);

  async function handleEnable() {
    setLoading(true);
    try {
      await pushService.subscribeToPush();
      setEnabled(true);
      alert("Notifications enabled");
    } catch (e) {
      console.error("Push subscribe failed", e);
      alert("Could not enable notifications");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="p-2">
      <button
        onClick={handleEnable}
        disabled={loading}
        className="bg-gradient-to-r from-purple-500 to-pink-500 text-white px-3 py-2 rounded-lg font-semibold"
      >
        {enabled
          ? "Notifications Enabled"
          : loading
            ? "Enabling..."
            : "Enable Notifications"}
      </button>
    </div>
  );
}
