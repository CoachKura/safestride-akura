export function calculateDistance(points) {
  if (!points || points.length < 2) return 0;
  const toRad = (deg) => deg * (Math.PI / 180);
  const haversine = (p1, p2) => {
    const R = 6371;
    const dLat = toRad(p2.lat - p1.lat);
    const dLon = toRad(p2.lng - p1.lng);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(p1.lat)) *
        Math.cos(toRad(p2.lat)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  let total = 0;
  for (let i = 1; i < points.length; i++)
    total += haversine(points[i - 1], points[i]);
  return total;
}

export function formatPace(minPerKm) {
  const mins = Math.floor(minPerKm);
  const secs = Math.floor((minPerKm - mins) * 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
}
