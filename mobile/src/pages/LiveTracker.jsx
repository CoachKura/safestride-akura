import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import mapboxgl from "mapbox-gl";
import { supabase, offlineInsert } from "../services/supabase";
import { calculateDistance, formatPace } from "../utils/distance";
import "mapbox-gl/dist/mapbox-gl.css";
import gps from "../services/gps";

mapboxgl.accessToken =
  "pk.eyJ1IjoiYWt1cmFzYWZlc3RyaWRlMjAyNiIsImEiOiJjbWwyM3VqczUwZXQzM2xwc2RpcjB1ZzF2In0.JwAJmlhNvIYGjb1sWaQs2g";

export default function LiveTracker() {
  const navigate = useNavigate();
  const mapContainer = useRef(null);
  const map = useRef(null);

  const [tracking, setTracking] = useState(false);
  const [paused, setPaused] = useState(false);
  const [distance, setDistance] = useState(0);
  const [duration, setDuration] = useState(0);
  const [pace, setPace] = useState("0:00");
  const [gpsPoints, setGpsPoints] = useState([]);

  const watchId = useRef(null);
  const startTime = useRef(0);
  const pausedTime = useRef(0);

  useEffect(() => {
    if (mapContainer.current && !map.current) {
      map.current = new mapboxgl.Map({
        container: mapContainer.current,
        style: "mapbox://styles/mapbox/streets-v12",
        center: [77.5946, 12.9716],
        zoom: 15,
      });
    }
    return () => {
      if (watchId.current) navigator.geolocation.clearWatch(watchId.current);
    };
  }, []);

  useEffect(() => {
    let interval;
    if (tracking && !paused) {
      interval = setInterval(() => {
        const elapsed = Math.floor(
          (Date.now() - startTime.current - pausedTime.current) / 1000,
        );
        setDuration(elapsed);
        if (distance > 0) {
          const paceMinPerKm = elapsed / 60 / distance;
          setPace(formatPace(paceMinPerKm));
        }
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [tracking, paused, distance]);

  function startTracking() {
    setTracking(true);
    setPaused(false);
    startTime.current = Date.now();
    watchId.current = navigator.geolocation.watchPosition(
      (position) => {
        const point = {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          timestamp: new Date().toISOString(),
          accuracy: position.coords.accuracy,
        };
        setGpsPoints((prev) => {
          const newPoints = [...prev, point];
          if (newPoints.length > 1) {
            const totalDist = calculateDistance(newPoints);
            setDistance(totalDist);
          }
          if (map.current) {
            map.current.flyTo({ center: [point.lng, point.lat], zoom: 16 });
            const coordinates = newPoints.map((p) => [p.lng, p.lat]);
            if (map.current.getSource("route")) {
              map.current.getSource("route").setData({
                type: "Feature",
                properties: {},
                geometry: { type: "LineString", coordinates },
              });
            } else {
              map.current.addSource("route", {
                type: "geojson",
                data: {
                  type: "Feature",
                  properties: {},
                  geometry: { type: "LineString", coordinates },
                },
              });
              map.current.addLayer({
                id: "route",
                type: "line",
                source: "route",
                layout: { "line-join": "round", "line-cap": "round" },
                paint: { "line-color": "#667eea", "line-width": 5 },
              });
            }
          }
          return newPoints;
        });
      },
      (error) => console.error("GPS error:", error),
      { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 },
    );
  }

  function pauseTracking() {
    setPaused(true);
    pausedTime.current += Date.now() - startTime.current;
    if (watchId.current) {
      navigator.geolocation.clearWatch(watchId.current);
      watchId.current = null;
    }
  }

  function resumeTracking() {
    setPaused(false);
    startTime.current = Date.now();
    startTracking();
  }

  async function finishTracking() {
    if (watchId.current) navigator.geolocation.clearWatch(watchId.current);
    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (user) {
        const { queued } = await offlineInsert("activity_logs", {
          athlete_id: user.id,
          activity_date: new Date().toISOString().split("T")[0],
          distance_km: distance,
          duration_minutes: Math.floor(duration / 60),
          activity_type: "Run",
          gps_data: {
            route: gpsPoints,
            totalDistance: distance,
            avgPace: pace,
          },
        });
        alert(
          `Run saved! ${distance.toFixed(2)} km in ${Math.floor(duration / 60)} min`,
        );
        navigate("/history");
      }
    } catch (error) {
      console.error("Error saving run:", error);
      alert("Error saving run. Please try again.");
    }
  }

  function formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  }

  if (!tracking) {
    return (
      <div className="min-h-screen bg-gray-50 flex flex-col items-center justify-center p-6">
        <div className="text-6xl mb-6">🏃</div>
        <h1 className="text-3xl font-bold text-gray-800 mb-4">Ready to Run?</h1>
        <p className="text-gray-600 text-center mb-8">
          Track your run with GPS and monitor your pace in real-time
        </p>
        <button
          onClick={startTracking}
          className="bg-primary text-white px-12 py-4 rounded-full text-xl font-semibold shadow-lg hover:bg-opacity-90 transition"
        >
          Start Tracking
        </button>
        <button
          onClick={() => navigate("/dashboard")}
          className="mt-4 text-gray-600 hover:text-gray-800"
        >
          Cancel
        </button>
      </div>
    );
  }

  return (
    <div className="relative h-screen w-screen">
      <div ref={mapContainer} className="absolute inset-0" />
      <div className="absolute bottom-0 left-0 right-0 bg-white rounded-t-3xl p-6 shadow-2xl">
        <div className="grid grid-cols-3 gap-4 mb-6">
          <div className="bg-gray-100 rounded-2xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-800">
              {distance.toFixed(2)}
            </div>
            <div className="text-sm text-gray-600">km</div>
          </div>
          <div className="bg-gray-100 rounded-2xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-800">
              {formatDuration(duration)}
            </div>
            <div className="text-sm text-gray-600">duration</div>
          </div>
          <div className="bg-gray-100 rounded-2xl p-4 text-center">
            <div className="text-2xl font-bold text-gray-800">{pace}</div>
            <div className="text-sm text-gray-600">min/km</div>
          </div>
        </div>
        <div className="flex items-center justify-center mb-6">
          <div className="flex items-center gap-2 bg-red-100 text-red-600 px-4 py-2 rounded-full">
            <div className="w-3 h-3 bg-red-600 rounded-full animate-pulse"></div>
            <span className="font-semibold">Recording</span>
            <span className="text-sm">GPS Points: {gpsPoints.length}</span>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          {paused ? (
            <button
              onClick={resumeTracking}
              className="bg-green-500 text-white py-4 rounded-xl font-semibold text-lg shadow-lg hover:bg-opacity-90 transition"
            >
              Resume 🎮
            </button>
          ) : (
            <button
              onClick={pauseTracking}
              className="bg-warning text-white py-4 rounded-xl font-semibold text-lg shadow-lg hover:bg-opacity-90 transition"
            >
              Pause 🎮
            </button>
          )}
          <button
            onClick={finishTracking}
            className="bg-danger text-white py-4 rounded-xl font-semibold text-lg shadow-lg hover:bg-opacity-90 transition"
          >
            Finish 🎮
          </button>
        </div>
      </div>
    </div>
  );
}
