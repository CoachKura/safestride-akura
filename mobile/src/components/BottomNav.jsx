import { useNavigate } from "react-router-dom";

export default function BottomNav({ active }) {
  const navigate = useNavigate();
  const tabs = [
    { id: "dashboard", icon: "🏠", label: "Dashboard", path: "/dashboard" },
    { id: "track", icon: "📍", label: "Track", path: "/track" },
    { id: "history", icon: "📊", label: "History", path: "/history" },
    { id: "profile", icon: "👤", label: "Profile", path: "/profile" },
  ];
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 safe-area-inset-bottom">
      <div className="grid grid-cols-4">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => navigate(tab.path)}
            className={`py-3 flex flex-col items-center gap-1 transition ${active === tab.id ? "text-primary" : "text-gray-500"}`}
          >
            <div className="text-2xl">{tab.icon}</div>
            <div className="text-xs font-medium">{tab.label}</div>
          </button>
        ))}
      </div>
    </div>
  );
}
