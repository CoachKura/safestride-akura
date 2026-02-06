import { useState, useEffect } from "react";

export default function InstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState(null);
  const [showPrompt, setShowPrompt] = useState(false);

  useEffect(() => {
    const handler = (e) => {
      e.preventDefault();
      setDeferredPrompt(e);
      setShowPrompt(true);
    };
    window.addEventListener("beforeinstallprompt", handler);
    if (window.matchMedia("(display-mode: standalone)").matches)
      setShowPrompt(false);
    return () => window.removeEventListener("beforeinstallprompt", handler);
  }, []);

  async function handleInstall() {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const choice = await deferredPrompt.userChoice;
    console.log("Install outcome", choice.outcome);
    setDeferredPrompt(null);
    setShowPrompt(false);
  }

  function handleDismiss() {
    setShowPrompt(false);
  }

  if (!showPrompt) return null;

  return (
    <div className="fixed bottom-20 left-4 right-4 bg-white rounded-2xl shadow-2xl p-4 border-2 border-primary z-50 animate-slide-up">
      <div className="flex items-center gap-3">
        <div className="text-4xl">📱</div>
        <div className="flex-1">
          <div className="font-semibold text-gray-800">Install SafeStride</div>
          <div className="text-sm text-gray-600">
            Add to home screen for quick access
          </div>
        </div>
      </div>
      <div className="flex gap-2 mt-4">
        <button
          onClick={handleInstall}
          className="flex-1 bg-primary text-white py-3 rounded-xl font-semibold hover:bg-opacity-90 transition"
        >
          Install
        </button>
        <button
          onClick={handleDismiss}
          className="px-6 py-3 rounded-xl font-semibold text-gray-600 hover:bg-gray-100 transition"
        >
          Not Now
        </button>
      </div>
    </div>
  );
}
