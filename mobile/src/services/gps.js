let watchId = null;
let lastPosition = null;
let listeners = new Set();

const defaultOptions = {
  enableHighAccuracy: true,
  maximumAge: 0,
  timeout: 10000
};

function toPoint(position) {
  const c = position.coords;
  return {
    lat: c.latitude,
    lng: c.longitude,
    timestamp: position.timestamp || Date.now(),
    accuracy: c.accuracy ?? null,
    elevation: c.altitude ?? null,
    speed: c.speed ?? null
  };
}

export function startTracking(onUpdate, options = {}) {
  if (!('geolocation' in navigator)) {
    const err = new Error('Geolocation not supported');
    if (onUpdate) onUpdate({ error: err });
    return null;
  }

  const opts = { ...defaultOptions, ...options };

  if (watchId !== null) return watchId;

  watchId = navigator.geolocation.watchPosition(
    (pos) => {
      const point = toPoint(pos);
      lastPosition = point;
      listeners.forEach((cb) => cb({ point }));
      if (onUpdate) onUpdate({ point });
    },
    (error) => {
      const err = new Error(error.message || 'Unknown geolocation error');
      listeners.forEach((cb) => cb({ error: err }));
      if (onUpdate) onUpdate({ error: err });
    },
    opts
  );

  return watchId;
}

export function stopTracking() {
  if (watchId !== null && 'geolocation' in navigator) {
    navigator.geolocation.clearWatch(watchId);
  }
  watchId = null;
}

export function isTracking() {
  return watchId !== null;
}

export function getLastPosition() {
  return lastPosition;
}

export function addListener(cb) {
  listeners.add(cb);
  return () => listeners.delete(cb);
}

export default {
  startTracking,
  stopTracking,
  isTracking,
  getLastPosition,
  addListener
};
