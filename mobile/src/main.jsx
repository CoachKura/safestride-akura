import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import LiveTracker from "./pages/LiveTracker";
import "./services/syncInit";
import WorkoutLogger from "./pages/WorkoutLogger";
import SyncStatus from "./components/SyncStatus";
import History from "./pages/History";
import Profile from "./pages/Profile";
import InstallPrompt from "./components/InstallPrompt";
import "./index.css";
import PushToggle from "./components/PushToggle";

function App() {
  return (
    <BrowserRouter>
      <SyncStatus />
      <div className="fixed top-16 right-4 z-50">
        <PushToggle />
      </div>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/track" element={<LiveTracker />} />
        <Route path="/log" element={<WorkoutLogger />} />
        <Route path="/history" element={<History />} />
        <Route path="/profile" element={<Profile />} />
      </Routes>
      {/* Install Prompt for PWA */}
      <InstallPrompt />
    </BrowserRouter>
  );
}

createRoot(document.getElementById("root")).render(<App />);
