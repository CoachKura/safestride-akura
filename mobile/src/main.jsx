import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import LiveTracker from "./pages/LiveTracker";
import WorkoutLogger from "./pages/WorkoutLogger";
import History from "./pages/History";
import Profile from "./pages/Profile";
import "./index.css";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/track" element={<LiveTracker />} />
        <Route path="/log" element={<WorkoutLogger />} />
        <Route path="/history" element={<History />} />
        <Route path="/profile" element={<Profile />} />
      </Routes>
    </BrowserRouter>
  );
}

createRoot(document.getElementById("root")).render(<App />);
